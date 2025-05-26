# Security Policy

## Supported Versions

We currently support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 24.x.x  | :white_check_mark: |
| 23.x.x  | :white_check_mark: |
| < 23.0  | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in kube-web-view, please follow these steps:

1. **Do not disclose the vulnerability publicly** until it has been addressed.
2. Email the maintainer directly at henning@zalando.de with details about the vulnerability.
3. Include as much information as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

The maintainer will acknowledge your report within 48 hours and provide an estimated timeline for a fix.

## Security Measures

kube-web-view implements the following security measures:

1. **Non-root container**: The application runs as a non-root user (UID 1000) in the container.
2. **Read-only filesystem**: The container uses a read-only root filesystem.
3. **Secret handling**: By default, secret data is hidden and must be explicitly enabled.
4. **Resource limitations**: The deployment template includes resource limits to prevent DoS attacks.
5. **Regular dependency updates**: Dependencies are regularly updated to patch security vulnerabilities.
6. **Automated security scanning**: We use Trivy and other tools to scan for vulnerabilities.

## Best Practices for Deployment

When deploying kube-web-view, consider the following security best practices:

1. Use network policies to restrict access to the kube-web-view pod.
2. Consider implementing authentication (OAuth2) as described in the documentation.
3. Review the RBAC permissions and limit them if you don't need access to all resources.
4. Do not enable the `--show-secrets` flag in production environments unless absolutely necessary.
5. Deploy in a dedicated namespace with appropriate access controls.
6. Use TLS for all communications with the kube-web-view service.
=======
Use this section to tell people about which versions of your project are
currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 5.1.x   | :white_check_mark: |
| 5.0.x   | :x:                |
| 4.0.x   | :white_check_mark: |
| < 4.0   | :x:                |

## Reporting a Vulnerability

Use this section to tell people how to report a vulnerability.

Tell them where to go, how often they can expect to get an update on a
reported vulnerability, what to expect if the vulnerability is accepted or
declined, etc.
