resource "aws_cloudwatch_dashboard" "security_dashboard" {
  dashboard_name = "SecurityDashboard"
  
  dashboard_body = jsonencode({
    "widgets" = [
      {
        "type" = "metric",
        "x" = 0,
        "y" = 0,
        "width" = 12,
        "height" = 6,
        "properties" = {
          "metrics" = [
            [ "Security", "SAST_Vulnerabilities", "Build", "$\{Build\}" ]
          ],
          "title" = "SAST Vulnerabilities per Build",
          "period" = 3600,
          "stat" = "Sum",
          "region" = "us-west-2"
        }
      },
      {
        "type" = "metric",
        "x" = 0,
        "y" = 6,
        "width" = 12,
        "height" = 6,
        "properties" = {
          "metrics" = [
            [ "Security", "DAST_Vulnerabilities", "Build", "$\{Build\}" ]
          ],
          "title" = "DAST Vulnerabilities per Build",
          "period" = 3600,
          "stat" = "Sum",
          "region" = "us-west-2"
        }
      },
      {
        "type" = "metric",
        "x" = 0,
        "y" = 12,
        "width" = 12,
        "height" = 6,
        "properties" = {
          "metrics" = [
            [ "Security", "DepScan_Vulnerabilities", "Build", "$\{Build\}" ]
          ],
          "title" = "Dependency Scanning Vulnerabilities per Build",
          "period" = 3600,
          "stat" = "Sum",
          "region" = "us-west-2"
        }
      }
    ]
  })
}
