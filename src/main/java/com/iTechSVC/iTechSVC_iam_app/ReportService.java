package com.iTechSVC.iTechSVC_iam_app; // package for this service

import org.springframework.security.access.prepost.PreAuthorize; // used for method-level authorization
import org.springframework.stereotype.Service; // marks this class as a service bean

@Service // tells Spring this class contains business logic
public class ReportService {

    @PreAuthorize("isAuthenticated()") // any logged-in user can call this method
    public String getEmployeeReport() {
        // pretend this is business logic that returns a normal report
        return "Employee report: basic company performance data.";
    }

    @PreAuthorize("hasRole('ADMIN')") // only ADMIN users can call this method
    public String getAdminReport() {
        // pretend this is sensitive business logic only admins may access
        return "Admin report: salary budget, audit flags, and privileged metrics.";
    }
}