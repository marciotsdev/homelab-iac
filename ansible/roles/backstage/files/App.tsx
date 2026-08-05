import {
  OpenIdConnectApi,
  ProfileInfoApi,
  BackstageIdentityApi,
  SessionApi,
} from '@backstage/core-plugin-api';
import {
  ApiBlueprint,
  configApiRef,
  createApiRef,
  discoveryApiRef,
  oauthRequestApiRef,
  createFrontendModule,
} from '@backstage/frontend-plugin-api';
import { OAuth2 } from '@backstage/core-app-api';
import { SignInPageBlueprint } from '@backstage/plugin-app-react';
import { SignInPage } from '@backstage/core-components';
import { createApp } from '@backstage/frontend-defaults';
import catalogPlugin from '@backstage/plugin-catalog/alpha';
import { navModule } from './modules/nav';

// SSO via Keycloak — ver docs/auth/keycloak no repo backstage/backstage e o
// README do @backstage-community/plugin-auth-backend-module-keycloak-provider
// (o backend nao inclui uma API de auth pronta para Keycloak, so o provider).
const keycloakAuthApiRef = createApiRef<
  OpenIdConnectApi & ProfileInfoApi & BackstageIdentityApi & SessionApi
>({
  id: 'auth.keycloak',
});

const keycloakAuthApi = ApiBlueprint.make({
  name: 'keycloak',
  params: defineParams =>
    defineParams({
      api: keycloakAuthApiRef,
      deps: {
        discoveryApi: discoveryApiRef,
        oauthRequestApi: oauthRequestApiRef,
        configApi: configApiRef,
      },
      factory: ({ discoveryApi, oauthRequestApi, configApi }) =>
        OAuth2.create({
          configApi,
          discoveryApi,
          oauthRequestApi,
          environment: configApi.getOptionalString('auth.environment'),
          provider: {
            // Precisa bater com a chave em auth.providers no app-config.
            id: 'keycloak',
            title: 'Keycloak',
            icon: () => null,
          },
          defaultScopes: ['openid', 'profile', 'email'],
        }),
    }),
});

const signInPage = SignInPageBlueprint.make({
  params: {
    loader: async () => props =>
      (
        <SignInPage
          {...props}
          provider={{
            id: 'keycloak-auth-provider',
            title: 'Keycloak',
            message: 'Entrar com o Keycloak do lab',
            apiRef: keycloakAuthApiRef,
          }}
        />
      ),
  },
});

export default createApp({
  features: [
    catalogPlugin,
    navModule,
    createFrontendModule({
      pluginId: 'app',
      extensions: [keycloakAuthApi, signInPage],
    }),
  ],
});
