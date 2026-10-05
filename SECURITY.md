# Security

## Reporting a vulnerability

Report security problems privately, not in a public issue. On GitHub, open the repository's **Security** tab and choose **Report a vulnerability**. Only the maintainers can see the report.

Include what you found, how to reproduce it, and what an attacker could do with it.

## What counts

A security problem in this module is anything that makes a database more exposed than its inputs say it should be: for example, a default that allows network access or turns off encryption, a security group rule or IAM permission broader than documented, a secret written to the Terraform state, or a validation that lets an insecure value through.

## Supported versions

Fixes are made to the latest release.
