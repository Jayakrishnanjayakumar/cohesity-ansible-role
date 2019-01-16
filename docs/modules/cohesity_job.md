# Cohesity Protection Job

## Table of Contents
- [Synopsis](#synopsis)
- [Requirements](#requirements)
- [Syntax](#syntax)
- [Examples](#examples)
  - [Create a new Physical Server Protection Job](#Create-a-new-Physical-Server-Protection-Job)
  - [Create a new VMware Server Protection Job](#Create-a-new-VMware-Server-Protection-Job)
  - [Remove an existing VMware Server Protection Job](#Remove-an-existing-VMware-Server-Protection-Job)
  - [Remove an existing VMware Server Protection Job and remove all Backups](#Remove-an-existing-VMware-Server-Protection-Job-and-remove-all-Backups)
  - [Start an existing VMware Server Protection Job](#Start-an-existing-VMware-Server-Protection-Job)
  - [Stop an actively running VMware Server Protection Job](#Stop-an-actively-running-VMware-Server-Protection-Job)
- [Parameters](#parameters)
- [Outputs](#outputs)

## Synopsis
[top](#cohesity-protection-job)

This Ansible Module registers, removes, starts, and stops the Cohesity Protection Job on a Cohesity cluster.  When executed in a playbook, the Cohesity Protection Job is validated and the appropriate state action is applied.

### Requirements
[top](#cohesity-protection-job)

* Cohesity DataPlatform running version 6.0 or higher
* Ansible version 2.6 or higher
  * The [Ansible Control Machine](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#control-machine-requirements) must be a system running one of the following UNIX operating systems: Linux (Red Hat, Debian, CentOS), macOS, or any of the BSDs. Windows is not supported for the Control Machine.
* Python version 2.6 or higher

> **Note:**
  - Currently, the Ansible Module requires Full Cluster Administrator access.

## Syntax
[top](#cohesity-protection-job)

```yaml
- cohesity_job:
    server: <ip or hostname for cohesity cluster>
    cohesity_admin: <username with cluster level permissions>
    cohesity_password: <password for the selected user>
    validate_certs: <boolean to determine if SSL certificates should be validated>
    state: <state of the Protection Job>
    name: <assigned name of the Protection Job>
    description: <optional description for the job>
    environment: <protection source environment type>
    protection_sources:
      - <list of registered protection sources to include in the job>
    protection_policy: <existing protection policy name to assign to the job>
    storage_domain: <existing storage domain name to assign to the job>
    time_zone: <time_zone for the protection job>
    start_time: <time to begin the protection job>
    delete_backups: <boolean to determine if backups be deleted when job removed>
    ondemand_run_type: <backup run type>
    cancel_active: <boolean to determine if an active job should be canceled>
```

## Examples
[top](#cohesity-protection-job)

### Create a new Physical Server Protection Job
[top](#cohesity-protection-job)

```yaml
- cohesity_job:
    cluster: cohesity.lab
    username: admin
    password: password
    state: present
    name: myhost
    environment: Physical
    protection_sources:
      - myhost.domain.lab
    protection_policy: Bronze
    storage_domain: Default
```

### Create a new VMware Server Protection Job
[top](#cohesity-protection-job)

```yaml
- cohesity_job:
    cluster: cohesity.lab
    username: admin
    password: password
    state: present
    name: myvcenter
    environment: VMware
    protection_sources:
      - myvcenter.domain.lab
    protection_policy: Gold
    storage_domain: Default
```

### Remove an existing VMware Server Protection Job
[top](#cohesity-protection-job)

```yaml
- cohesity_job:
    cluster: cohesity.lab
    username: admin
    password: password
    state: absent
    name: myvcenter
    environment: VMware

```

### Remove an existing VMware Server Protection Job and remove all Backups
[top](#cohesity-protection-job)

```yaml
- cohesity_job:
    cluster: cohesity.lab
    username: admin
    password: password
    state: absent
    name: myvcenter
    environment: VMware
    delete_backups: True

```

### Start an existing VMware Server Protection Job
[top](#cohesity-protection-job)

```yaml
- cohesity_job:
    cluster: cohesity.lab
    username: admin
    password: password
    state: started
    name: myvcenter
    environment: VMware

```

### Stop an actively running VMware Server Protection Job
[top](#cohesity-protection-job)

```yaml
- cohesity_job:
    cluster: cohesity.lab
    username: admin
    password: password
    state: stopped
    name: myvcenter
    environment: VMware
```


## Parameters
[top](#cohesity-protection-job)

| Required | Parameters | Type | Choices/Defaults | Comments |
| --- | --- | --- | --- | --- |
| X | **cluster** | String | | IP or FQDN for the Cohesity cluster |
| X | **cohesity_admin** | String | | Username with which Ansible will connect to the Cohesity cluster. Domain-specific credentails can be configured in one of two formats.<br>- Domain\\username<br>- username@domain |
| X | **cohesity_password** | String | | Password belonging to the selected Username.  This parameter is not logged. |
|   | validate_certs | Boolean | False | Switch that determines whether SSL Validation is enabled. |
|   | state | Choice | -**present**<br>-absent<br>-started<br>-stopped | Determines the state of the Protection Job. |
| X | name | String | | Name to assign to the Protection Job.  Must be unique. |
|   | description | String | | Optional Description to assign to the Protection Job |
| X | environment | Choice | -Physical<br>-VMware<br>-GenericNas | Specifies the environment type (such as VMware or SQL) of the Protection Source this Job is protecting. |
|   | protection_sources | Array |  | Valid list of endpoint names for existing Protection Sources to be included in the job. **Required** when *state=present*. |
|   | protection_policy | String |  | Valid policy name or ID for an existing Protection Policy to be assigned to the job. **Required** when *state=present*. |
|   | storage_domain | String | | Existing Storage Domain with which the Protection Job will be associated. Required when *state=present*. |
|   | time_zone | String | America/Los_Angeles | Specifies the time zone to use when calculating time for this Protection Job (such as the Job start time). The time must be specified in the **Area/Location** format, such as "America/New_York". |
|   | start_time | String | | Specifies the registered start time for the Protection Job.  Format must be 24hr time in either the *HHMM* or *HH:MM* style.  If not configured, then Cohesity will automatically select a time. Optional when *state=present*. |
|   | delete_backups | Boolean | False | Specifies whether Snapshots generated by the Protection Job should also be deleted when the Job is deleted. Optional and valid only when *state=absent*. |
|   | ondemand_run_type | Choice | -**Regular**<br>-Full<br>-Log<br>-System | Specifies the type of OnDemand Backup.  Valid only when *state=started*. |
|   | cancel_active | Boolean | False | Specifies whether the Current Running Backup Job is canceled.  If *False*, active jobs are not stopped and a failure is raised. Optional and valid only when *state=stopped* |


## Outputs
[top](#cohesity-protection-job)

- Returns the registered Protection Job ID

