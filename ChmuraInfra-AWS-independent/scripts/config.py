from keycloak import KeycloakAdmin


FRONT_URL = "http://notatnik-alb-108291179.us-east-1.elb.amazonaws.com"
KEYCLOAK_URL = f"{FRONT_URL}:8081/"
ADMIN_USER = 'admin'
ADMIN_PASS = 'admin123'
NEW_REALM_NAME = "simple-notatnik"


master_admin = KeycloakAdmin(
    server_url=KEYCLOAK_URL,
    username=ADMIN_USER,
    password=ADMIN_PASS,
    realm_name='master',
    verify=False
)


print(f"Tworzę realm: {NEW_REALM_NAME}...")
master_admin.create_realm(payload={"realm": NEW_REALM_NAME, "enabled": True})


keycloak_admin = KeycloakAdmin(
    server_url=KEYCLOAK_URL,
    username=ADMIN_USER,
    password=ADMIN_PASS,
    realm_name=NEW_REALM_NAME,    
    user_realm_name='master',     
    verify=False
)


print("Tworzę clienta...")
keycloak_admin.create_client(payload={
    "clientId": "frontend-client",
    "enabled": True,
    "protocol": "openid-connect",
    "publicClient": True,               
    "standardFlowEnabled": True,        
    "directAccessGrantsEnabled": False, 
    "serviceAccountsEnabled": False,    
    "redirectUris": [FRONT_URL], 
    "webOrigins": ["+"]
})

print("Tworzę użytkownika...")
user_id = keycloak_admin.create_user(payload={
    "email": "jan@kowalski.pl",
    "username": "jan_kowalski",
    "enabled": True,
    "firstName": "Jan",
    "lastName": "Kowalski"
})
keycloak_admin.set_user_password(
    user_id=user_id, 
    password="123", 
    temporary=False
)
print("Konfiguracja zakończona sukcesem!")