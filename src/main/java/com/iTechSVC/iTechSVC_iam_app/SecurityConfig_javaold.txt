package com.iTechSVC.iTechSVC_iam_app; // this must match your package structure

import org.springframework.context.annotation.Bean; // tells Spring to manage objects
import org.springframework.context.annotation.Configuration; // marks this class as a config class
import org.springframework.security.config.Customizer; // used for default login setup
import org.springframework.security.config.annotation.web.builders.HttpSecurity; // main security config tool
import org.springframework.security.web.SecurityFilterChain; // represents the security rules pipeline - it is the chain of security rules applied to requests

@Configuration // tells Spring: this class contains configuration logic
public class SecurityConfig {

    @Bean // tells Spring: create and manage this object (SecurityFilterChain)
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        http
            // define who can access what
            .authorizeHttpRequests(auth -> auth

                // allow anyone to access the home page without logging in ( public access page)
                .requestMatchers("/", "/home").permitAll()

                // require login for dashboard
                .requestMatchers("/dashboard").authenticated()

                // any other request must also be authenticated
                .anyRequest().authenticated()
            )

            // enable login form (Spring's default login page)
            .formLogin(Customizer.withDefaults())
                // enable logout support (Spring's default logout handling)
            
            .logout(logout -> logout
                .logoutUrl("/logout") // URL to trigger logout
                .logoutSuccessUrl("/") // where to go after logout
                .invalidateHttpSession(true) // clear session on logout - invalidate the HTTP session so the server forgets the logged-in user
                .deleteCookies("JSESSIONID") // delete JSESSIONID  session cookie from browser on logout
            );

        // build and return the security configuration
        return http.build();
    }
}