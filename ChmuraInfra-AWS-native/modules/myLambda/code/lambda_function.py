import boto3
import urllib.parse
import os

s3 = boto3.client("s3")

DEST_PREFIX = "notepadApp/"  # docelowy "folder" w S3

def lambda_handler(event, context):
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        raw_key = record["s3"]["object"]["key"]
        key = urllib.parse.unquote_plus(raw_key)

        # Nie rób nic, jeśli plik już jest w notepadApp/
        if key.startswith(DEST_PREFIX):
            print(f"Skip (already in {DEST_PREFIX}): {key}")
            continue

        # Zachowujemy całą ścieżkę pod nowym prefixem,
        # np. "uploads/a.png" -> "notepadApp/uploads/a.png"
        dest_key = f"{DEST_PREFIX}{key}"

        print(f"Moving {bucket}/{key} -> {bucket}/{dest_key}")

        # 1) Kopiuj do docelowego miejsca
        s3.copy_object(
            Bucket=bucket,
            Key=dest_key,
            CopySource={"Bucket": bucket, "Key": key},
            MetadataDirective="COPY"
        )

        # 2) Usuń oryginał (to jest realne "przeniesienie")
        s3.delete_object(Bucket=bucket, Key=key)

    return {"statusCode": 200, "body": "OK"}
