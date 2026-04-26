package com.iTechSVC.iTechSVC_iam_app; // package name for this class

import java.util.List;

import org.springframework.security.core.Authentication; // gives access to logged-in user info
import org.springframework.security.core.GrantedAuthority; // represents a user role/authority
import org.springframework.stereotype.Controller; // marks this class as a web controller
import org.springframework.ui.Model; // sends data from Java to HTML
import org.springframework.web.bind.annotation.GetMapping; // maps HTTP GET requests to methods
import org.springframework.web.bind.annotation.RequestParam; // reads query parameters from the URL

@Controller // tells Spring this class handles browser page requests
public class HomeController {
    private final ReportService reportService; // service for generating reports

    public HomeController(ReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping("/") // when user visits the home page
    public String home(Model model, @RequestParam(value = "logout", required = false) String logout) {
        model.addAttribute("appName", "iTechSVC  - IAM APP"); // app name sent to HTML
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
        String UserRole = authentication.getAuthorities().toString(); // get the roles of the logged-in user

        model.addAttribute("title", "Employee Dashboard"); // dashboard page title
        model.addAttribute("info", "This page is protected and requires login."); // info text
        model.addAttribute("username", username); // send logged-in username to HTML
        List<String> roles = authentication.getAuthorities().stream()
            .map(GrantedAuthority::getAuthority) // convert each authority object to text like ROLE_EMPLOYEE
            .toList();
        model.addAttribute("authStatus", authentication.isAuthenticated()); // true/false login state
        model.addAttribute("roles", roles); // send user roles to HTML
        model.addAttribute("details", authentication.getDetails()); // send additional auth details to HTML
        model.addAttribute("principal", authentication.getPrincipal()); // send principal info to HTML
        //model.addAttribute("roles2", authentication.getAuthorities()); - this gets the same info as the " ,roles" attribute but in a different format (as a list of authority objects instead of strings)
        return "dashboard"; // render templates/dashboard.html
    }

    @GetMapping("/admin") // handles admin page
    public String admin(Model model, Authentication authentication) {
        String username = authentication.getName(); // current username

        // collect all roles/authorities of the logged-in user into a list of strings
        List<String> roles = authentication.getAuthorities()
                .stream()
                .map(GrantedAuthority::getAuthority) // convert each authority object to text
                .toList();
        model.addAttribute("title", "Admin Page"); // page title
        model.addAttribute("message", "Only ADMIN users can access this page."); // admin message
        model.addAttribute("username", username); // logged-in username
        model.addAttribute("roles", roles); // send user roles to HTML

        return "admin"; // render admin.html
    }
    
     @GetMapping("/access-denied") // handles custom access denied page
    public String accessDenied(Model model, Authentication authentication) {
        if (authentication != null) {
            model.addAttribute("username", authentication.getName()); // show current username
        } else {
            model.addAttribute("username", "anonymous"); // fallback if no login exists
        }

        model.addAttribute("title", "Access Denied"); // page title
        model.addAttribute("message", "You do not have permission to access that page."); // friendly message

        return "access-denied"; // render access-denied.html
    }

    @GetMapping("/reports") // endpoint for all logged-in users
    public String employeeReport(Model model, Authentication authentication) {
        String report = reportService.getEmployeeReport(); // service method protected by @PreAuthorize

        model.addAttribute("title", "Employee Report"); // page title
        model.addAttribute("username", authentication.getName()); // current username
        model.addAttribute("reportData", report); // report text for HTML

        return "report"; // render report.html
    }

    @GetMapping("/reports/admin") // endpoint for admin report
    public String adminReport(Model model, Authentication authentication) {
        String report = reportService.getAdminReport(); // service method protected by @PreAuthorize

        model.addAttribute("title", "Admin Report"); // page title
        model.addAttribute("username", authentication.getName()); // current username
        model.addAttribute("reportData", report); // report text for HTML

        return "report"; // render report.html
    }
}