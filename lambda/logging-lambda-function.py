import json
import boto3
import logging
from datetime import datetime
import time

# Initialize CloudWatch Logs client
logs = boto3.client('logs', region_name='eu-west-1')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def create_log_group_and_stream(log_group_name, log_stream_name):
    """Creates a log group and log stream if they do not exist."""
    try:
        # Check if the log group exists
        response = logs.describe_log_groups(logGroupNamePrefix=log_group_name)
        if not any(group['logGroupName'] == log_group_name for group in response['logGroups']):
            # Create log group if it doesn't exist
            logs.create_log_group(logGroupName=log_group_name)
            logger.info(f"Created log group: {log_group_name}")
        else:
            logger.info(f"Log group {log_group_name} already exists.")
        
    except Exception as e:
        logger.error(f"Error checking or creating log group {log_group_name}: {e}")
        raise e

    try:
        # Check if the log stream exists
        response = logs.describe_log_streams(logGroupName=log_group_name, logStreamNamePrefix=log_stream_name)
        if not any(stream['logStreamName'] == log_stream_name for stream in response['logStreams']):
            # Create log stream if it doesn't exist
            logs.create_log_stream(logGroupName=log_group_name, logStreamName=log_stream_name)
            logger.info(f"Created log stream: {log_stream_name}")
        else:
            logger.info(f"Log stream {log_stream_name} already exists.")
    except Exception as e:
        logger.error(f"Error checking or creating log stream {log_stream_name}: {e}")
        raise e

    # Wait a few seconds to log stream is ready
    time.sleep(2)

def send_to_cloudwatch(findings, apllication_language, build_number, test_type):
    # Define log group and stream names
    log_group_name = apllication_language
    log_stream_name = f"{test_type}/{build_number}"

    # Create log group and log stream if they don't exist
    create_log_group_and_stream(log_group_name, log_stream_name)

    # Log each finding to CloudWatch
    for finding in findings:
        response = logs.put_log_events(
            logGroupName=log_group_name,
            logStreamName=log_stream_name,
            logEvents=[
                {
                    'timestamp': int(datetime.utcnow().timestamp() * 1000),
                    'message': json.dumps(finding)
                }
            ]
        )
        logger.info(f"Successfully sent finding to CloudWatch Logs: {response}")

def DepScan_scan_Safety(event, apllication_language, build_number, test_type):
    findings = []
    projects = event.get("results", {}).get("scan_results", {}).get("projects", [])
    for project in projects:
        for file in project.get("files", []):
            for dependency in file.get("results", {}).get("dependencies", []):
                package_name = dependency.get("name", "unknown-package")
                for spec in dependency.get("specifications", []):
                    raw_version = spec.get("raw", "unknown-version")
                    vulnerabilities_found = len(spec.get("vulnerabilities", {}).get("known_vulnerabilities", []))
                    vulnerabilities = spec.get("vulnerabilities")
                    if vulnerabilities["remediation"]:
                        recommended = vulnerabilities["remediation"].get("recommended", "No recommendation available")
                    else:
                        recommended = "No recommendation available"

                    for vulnerability in spec.get("vulnerabilities", {}).get("known_vulnerabilities", []):
                        current_time = datetime.utcnow().isoformat() + "Z"
                        vuln_id = vulnerability.get("id", "unknown-id")
                        vulnerable_spec = vulnerability.get("vulnerable_spec", "unknown-spec")

                        finding = {
                            'SchemaVersion': '2018-10-08',
                            'Id': f"{package_name}-{vuln_id}",
                            'Title': f"Vulnerability in {package_name}",
                            'Description': f"Vulnerability {vuln_id} affects {package_name} {vulnerable_spec}",
                            'GeneratorId': "DepCheck",
                            'Severity': {
                                'Label': "UNKNOWN"
                            },
                            'Resources': [
                                {
                                    'Type': 'Dependency',
                                    'Id': package_name
                                }
                            ],
                            'CreatedAt': current_time,
                            'UpdatedAt': current_time,
                            'ProductFields': {
                                'DependencyName': package_name,
                                'DependencyVersion': raw_version
                            },
                            'Remediation': {
                                'vulnerabilities_found': vulnerabilities_found,
                                'recommended': recommended,
                            },
                            'TestType': test_type,
                            'BuildNumber': build_number,
                        }
                        findings.append(finding)
    try:
        send_to_cloudwatch(findings, apllication_language, build_number, test_type)

    except Exception as e:
        logger.error(f"Error sending findings to CloudWatch Logs: {e}")
        raise e

    return findings

def DepScan_scan_Snyk(event, apllication_language, build_number, test_type):
    findings = []
    # Parsing Snyk results from the event
    for result in event.get("results", []):
        vuln_id = result.get("id", "unknown-id")
        package_name = result.get("packageName", "unknown-package")
        raw_version = result.get("version", "unknown-version")
        severity = result.get("severity", "UNKNOWN")
        description = result.get("description", "No description available")
        remediation = result.get("remediation", {}).get("recommended", "No recommendation available")

        # Extracting the CVSS score (if available) and setting the severity label
        cvss_score = result.get("cvssScore", 0)
        if severity.lower() == "high":
            severity_label = "HIGH"
        elif severity.lower() == "medium":
            severity_label = "MEDIUM"
        elif severity.lower() == "low":
            severity_label = "LOW"
        else:
            severity_label = "UNKNOWN"

        # Additional information from references and other attributes in the vulnerability
        references = result.get("references", [])
        reference_urls = [ref.get("url", "No URL") for ref in references]

        # Create the finding object for each vulnerability
        current_time = datetime.utcnow().isoformat() + "Z"
        finding = {
            'SchemaVersion': '2018-10-08',
            'Id': f"{package_name}-{vuln_id}",
            'Title': f"Vulnerability in {package_name}",
            'Description': f"Vulnerability {vuln_id} affects {package_name} ({description})",
            'GeneratorId': "DepCheck",
            'Severity': {
                'Label': severity_label,
                'CVSS': cvss_score
            },
            'Resources': [
                {
                    'Type': 'Dependency',
                    'Id': package_name
                }
            ],
            'CreatedAt': current_time,
            'UpdatedAt': current_time,
            'ProductFields': {
                'DependencyName': package_name,
                'DependencyVersion': raw_version,
                'CVSSScore': cvss_score
            },
            'Remediation': {
                'recommended': remediation,
            },
            'TestType': test_type,
            'BuildNumber': build_number,
            'References': reference_urls
        }

        # Add the finding to the list
        findings.append(finding)

    # Send findings to cloudwatch
    try:
        send_to_cloudwatch(findings, apllication_language, build_number, test_type)
    except Exception as e:
        logger.error(f"Error sending findings to CloudWatch Logs: {e}")
        raise e

    return findings

              
def SAST_scan_Semgrep(event, apllication_language, build_number, test_type):
    vulnerabilities = event.get("results", {}).get("results", [])

    findings = []

    for vulnerability in vulnerabilities:
        current_time = datetime.utcnow().isoformat() + "Z"
        fix = vulnerability['extra'].get('fix', 'No fix provided') 
        finding = {
            'SchemaVersion': '2018-10-08', 
            'Id': f"{vulnerability['check_id']}-{vulnerability['path']}",
            'Title': vulnerability['check_id'],
            'Description': vulnerability['extra']['message'],
            'GeneratorId': vulnerability['check_id'],
            'Severity': {
                'Label': vulnerability['extra']['severity']  
            },
            'Resources': [
                {
                    'Type': 'Wagtail',
                    'Id': vulnerability['path']
                }
            ],
            'CreatedAt': current_time,  
            'UpdatedAt': current_time,
            'ProductFields': {
                'SemgrepRule': vulnerability['check_id']
            },
            'Remediation': {
                'Recommendation': {
                    'Text': fix
                }
            },
            'SourceUrl': vulnerability['extra']['metadata']['source'],
            'TestType': test_type, 
            'BuildNumber': build_number,
        }

        findings.append(finding)
    
    try:
        send_to_cloudwatch(findings, apllication_language, build_number, test_type)

    except Exception as e:
        logger.error(f"Error sending findings to CloudWatch Logs: {e}")
        raise e

    return findings

def SAST_scan_SonarQube(event, application_language, build_number, test_type):
    vulnerabilities = event.get("results", [])
    findings = []

    for vuln in vulnerabilities:
        current_time = datetime.utcnow().isoformat() + "Z"

        finding = {
            'SchemaVersion': '2018-10-08',
            'Id': vuln.get('key', 'Unknown-ID'),
            'Title': vuln.get('rule', 'Unknown Rule'),
            'Description': vuln.get('message', 'No message provided'),
            'GeneratorId': vuln.get('project', 'Unknown Project'),
            'Severity': {
                'Label': vuln.get('severity', 'LOW')
            },
            'Resources': [
                {
                    'Type': 'SourceCode',
                    'Id': vuln.get('component', 'Unknown Component'),
                    'Details': {
                        'File': vuln.get('component'),
                        'Line': vuln.get('line'),
                        'Author': vuln.get('author', 'N/A'),
                        'Scope': vuln.get('scope', 'MAIN'),
                        'Hash': vuln.get('hash')
                    }
                }
            ],
            'CreatedAt': current_time,
            'UpdatedAt': current_time,
            'ProductFields': {
                'SonarQubeRule': vuln.get('rule'),
                'Effort': vuln.get('effort', 'N/A'),
                'Tags': ','.join(vuln.get('tags', []))
            },
            'Remediation': {
                'Recommendation': {
                    'Text': vuln.get('message', 'No recommendation')
                }
            },
            'SourceUrl': f"https://sonarqube.riga.services/project/issues?id={vuln.get('project')}&open={vuln.get('key')}",
            'TestType': test_type,
            'BuildNumber': build_number
        }

        findings.append(finding)

    try:
        send_to_cloudwatch(findings, application_language, build_number, test_type)
    except Exception as e:
        logger.error(f"Error sending SonarQube findings to CloudWatch Logs: {e}")
        raise e

    return findings

def ImageScan_scan(event, apllication_language, build_number, test_type):
    results = event.get("results", {}).get("Results", [])
    findings = []

    for result in results:
        target = result.get("Target", "unknown-target")
        vulnerabilities = result.get("Vulnerabilities", [])

        for vulnerability in vulnerabilities:
            vuln_id = vulnerability.get("VulnerabilityID", "unknown-id")
            pkg_name = vulnerability.get("PkgName", "unknown-package")
            installed_version = vulnerability.get("InstalledVersion", "unknown-version")
            severity = vulnerability.get("Severity", "UNKNOWN")
            title = vulnerability.get("Title", "No title available")
            description = vulnerability.get("Description", "No description available")
            primary_url = vulnerability.get("PrimaryURL", "No URL available")
            published_date = vulnerability.get("PublishedDate", "unknown-published-date")
            cve_ids = vulnerability.get("CweIDs", [])
            
            # Prepare remediation or fix (if available)
            references = vulnerability.get("References", [])
            
            current_time = datetime.utcnow().isoformat() + "Z"

            finding = {
                'SchemaVersion': '2018-10-08',
                'Id': f"{pkg_name}-{vuln_id}",
                'Title': title,
                'Description': description,
                'GeneratorId': "Trivy",
                'Severity': {
                    'Label': severity
                },
                'Resources': [
                    {
                        'Type': 'DockerImage',
                        'Id': target
                    }
                ],
                'CreatedAt': current_time,
                'UpdatedAt': current_time,
                'ProductFields': {
                    'PackageName': pkg_name,
                    'InstalledVersion': installed_version,
                },
                'Remediation': {
                    'Text': references
                },
                'SourceUrl': primary_url,
                'CweIDs': cve_ids,
                'PublishedDate': published_date,
                'TestType': test_type,
                'BuildNumber': build_number,
            }

            findings.append(finding)
    
    try:
        send_to_cloudwatch(findings, apllication_language, build_number, test_type)

    except Exception as e:
        logger.error(f"Error sending findings to CloudWatch Logs: {e}")
        raise e

    return findings


def lambda_handler(event, context):
    apllication_language = event.get('application_language', 'unknown')
    build_number = event.get('build_number', 'unknown')
    test_type = event.get('test_type', 'unknown')  # SAST, DAST, or DepCheck
    findings = []

    if test_type == 'DepScan':
        if apllication_language == 'Wagtail':
            findings = DepScan_scan_Safety(event, apllication_language, build_number, test_type)
        if apllication_language == 'AspNet':
            findings = DepScan_scan_Snyk(event, apllication_language, build_number, test_type)

    if test_type == 'ImageScan':
        findings = ImageScan_scan(event, apllication_language, build_number, test_type)
    
    if test_type == 'SAST':
        if apllication_language == 'Wagtail':
            findings = SAST_scan_Semgrep(event, apllication_language, build_number, test_type)
        if apllication_language == 'AspNet':
            findings = SAST_scan_SonarQube(event, apllication_language, build_number, test_type)

    # log the total number of findings
    logger.info(f"Total findings: {len(findings)}")