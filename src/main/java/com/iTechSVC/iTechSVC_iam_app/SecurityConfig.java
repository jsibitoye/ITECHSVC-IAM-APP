package com.iTechSVC.iTechSVC_iam_app; // must match your package

import org.springframework.context.annotation.Bean; // lets Spring manage returned objects
import org.springframework.context.annotation.Configuration; // marks this class as configuration
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity; // enables @PreAuthorize
import org.springframework.security.config.annotation.web.builders.HttpSecurity; // main security config object
import org.springframework.security.oauth2.client.oidc.web.logout.OidcClientInitiatedLogoutSuccessHandler; // stores Okta client config
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository; // handles Okta/OIDC logout
import org.springframework.security.web.SecurityFilterChain; // Spring Security filter chain
import org.springframework.security.web.authentication.logout.LogoutSuccessHandler; // logout handler interface


@Configuration // tells Spring this class contains configuration
@EnableMethodSecurity // enables method-level authorization like @PreAuthorize

public class SecurityConfig {

    @Bean // this defines the URL security rules - Note @Bean makes this method's return value managed by Spring and it tells spring to use the following object as a bean that can be injected into other parts of the app. In this case, it defines the security filter chain that Spring Security will use to protect our web application.
    public SecurityFilterChain securityFilterChain(
        HttpSecurity http,
            ClientRegistrationRepository clientRegistrationRepository // Spring auto-loads Okta client settings here
    ) throws Exception {

        http
            .authorizeHttpRequests(auth -> auth

                // home page is public
                .requestMatchers("/", "/home").permitAll()

                // access denied page must be public
                .requestMatchers("/access-denied").permitAll()

                // dashboard requires login
                .requestMatchers("/dashboard").authenticated()

                // admin page requires ADMIN role
                .requestMatchers("/admin").hasRole("ADMIN")

                // method security demo pages require login
                .requestMatchers("/reports", "/reports/admin").authenticated()

                // anything else requires login
                .anyRequest().authenticated()
            )
             
            // 🔴 THIS is what switches from local login → OKTA LOGIN

            // enable local login form (Spring's default login page)
            //.formLogin(Customizer.withDefaults())
            // OKTA LOGIN
                    .oauth2Login(oauth2 -> oauth2
                .defaultSuccessUrl("/dashboard", true)
            )

            // configure logout
            /* .logout(logout -> logout
                .logoutUrl("/logout") // logout endpoint
                .logoutSuccessUrl("/?logout") // go home after logout
                .invalidateHttpSession(true) // destroy session on server
                .deleteCookies("JSESSIONID") // remove session cookie
            )*/
           // setup okta aouth2 logout
           // logout from both Spring Boot local session and Okta session
            .logout(logout -> logout
                .logoutUrl("/logout") // user clicks this endpoint
                .logoutSuccessHandler(oidcLogoutSuccessHandler(clientRegistrationRepository)) // send user to Okta logout
                .invalidateHttpSession(true) // clear local Spring session
                .clearAuthentication(true) // clear Spring authentication object
                .deleteCookies("JSESSIONID") // remove local session cookie
            )
            // configure custom access denied page - what happens when user is authenticated but not allowed
            .exceptionHandling(ex -> ex
                .accessDeniedPage("/access-denied") // show our custom page instead of the white 403 page
            );

        return http.build(); // finalize the security setup
    }
    
    @Bean // creates the logout handler that knows how to call Okta logout
    public LogoutSuccessHandler oidcLogoutSuccessHandler(
            ClientRegistrationRepository clientRegistrationRepository
    ) {
        // this handler builds the Okta end-session/logout URL using the OIDC metadata
        OidcClientInitiatedLogoutSuccessHandler handler =
                new OidcClientInitiatedLogoutSuccessHandler(clientRegistrationRepository);

        // after Okta logs the user out, send browser back to this app
        // {baseUrl} becomes http://localhost:8080 during local development
        handler.setPostLogoutRedirectUri("{baseUrl}/");

        return handler;
    }
}