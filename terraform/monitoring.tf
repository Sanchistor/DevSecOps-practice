resource "aws_cloudwatch_dashboard" "security_dashboard" {
  dashboard_name = "SecurityDashboard"

  dashboard_body = jsonencode({
    "widgets" = [
      {
        "type"   = "metric",
        "x"      = 0,
        "y"      = 0,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "metrics" = [
            ["Security", "SAST_Vulnerabilities", "Build"]
          ],
          "title"  = "SAST Vulnerabilities per Build",
          "stat"   = "Sum",
          "region" = var.region,
          "period" = 300,
          "view"   = "timeSeries"
        }
      },
      {
        "type"   = "metric",
        "x"      = 0,
        "y"      = 6,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "metrics" = [
            ["Security", "DAST_Vulnerabilities", "Build"]
          ],
          "title"  = "DAST Vulnerabilities per Build",
          "stat"   = "Sum",
          "region" = var.region,
          "period" = 300,
          "view"   = "timeSeries"
        }
      },
      {
        "type"   = "metric",
        "x"      = 0,
        "y"      = 12,
        "width"  = 12,
        "height" = 6,
        "properties" = {
          "metrics" = [
            ["Security", "DepScan_Vulnerabilities", "Build"]
          ],
          "title"  = "Dependency Scan Vulnerabilities per Build",
          "stat"   = "Sum",
          "region" = var.region,
          "period" = 300,
          "view"   = "timeSeries"
        }
      }
    ]
  })
}
