package com.iTechSVC.iTechSVC_iam_app; // package name for this class

import org.springframework.security.core.Authentication; // gives access to logged-in user info
import org.springframework.stereotype.Controller; // marks this class as a web controller
import org.springframework.ui.Model; // sends data from Java to HTML
import org.springframework.web.bind.annotation.GetMapping; // maps HTTP GET requests to methods
import org.springframework.web.bind.annotation.RequestParam;

@Controller // tells Spring this class handles browser page requests
public class HomeController {

    @GetMapping("/") // when user visits the home page
    public String home(Model model, @RequestParam(value = "logout", required = false) String logout) {
        model.addAttribute("appName", "Company IAM App"); // app name sent to HTML
        model.addAttribute("message", "Welcome to our company application."); // message sent to HTML
        if (logout != null) {
            model.addAttribute("logoutMessage", "You have been logged out successfully.");
        }
        return "home"; // render templates/home.html
    }

    @GetMapping("/dashboard") // when user visits /dashboard
    public String dashboard(Model model, Authentication authentication) {
        // Authentication is automatically provided by Spring after login
        // it contains details about the logged-in user

        String username = authentication.getName(); // get the username of the logged-in user

        model.addAttribute("title", "Employee Dashboard"); // dashboard page title
        model.addAttribute("info", "This page is protected and requires login."); // info text
        model.addAttribute("username", username); // send logged-in username to HTML
        model.addAttribute("authStatus", authentication.isAuthenticated()); // true/false login state
        model.addAttribute("roles", authentication.getAuthorities()); // send user roles to HTML
        model.addAttribute("details", authentication.getDetails()); // send additional auth details to HTML
        model.addAttribute("principal", authentication.getPrincipal()); // send principal info to HTML

        return "dashboard"; // render templates/dashboard.html
    }
}