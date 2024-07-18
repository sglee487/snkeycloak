# Step 1: Build the custom theme
FROM node:22-alpine as theme-builder

WORKDIR /app

# Copy your project files to the container
COPY . .

# Install dependencies and build the custom theme
#RUN sudo apt-get install maven
# Install Maven
RUN apk add --no-cache maven
RUN #npm install -g yarn
RUN yarn install && npm run build-keycloak-theme

# Step 2: Build Keycloak
FROM quay.io/keycloak/keycloak:latest as keycloak-builder

WORKDIR /opt/keycloak
# Generate keypair for demonstration purposes
RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" -keystore conf/server.keystore

# Build Keycloak
RUN /opt/keycloak/bin/kc.sh build

# Step 3: Create the final image
FROM quay.io/keycloak/keycloak:latest

WORKDIR /opt/keycloak

# Copy built files from the builder
COPY --from=keycloak-builder /opt/keycloak/ /opt/keycloak/
COPY --from=theme-builder /app/dist_keycloak/keycloak-theme-for-kc-25-and-above.jar /opt/keycloak/providers/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
