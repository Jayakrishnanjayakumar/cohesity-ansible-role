# Task: Cohesity File Restore Operation

## Table of Contents
- [Synopsis](#synopsis)
- [Requirements](#requirements)
- [Ansible Variables](#Ansible-Variables)
- [Customize Your Playbooks](#Customize-your-playbooks)
  - [Restore a File from most recent snapshot](#Restore-a-File-from-most-recent-snapshot)
- [How the Task Works](#How-the-Task-works)

## Synopsis
[top](#task-cohesity-file-restore-operation)

Use this task to perform a Cohesity Restore operation

#### How It Works
- The task starts by determining whether the named task exists and is not running.
- Upon validation, the task creates a new Restore Operation (*state=present*) to recover files from the cluster.

### Requirements
[top](#task-cohesity-file-restore-operation)

* Cohesity Cluster running version 6.0 or higher
* Ansible version 2.6 or higher
  * The [Ansible Control Machine](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#control-machine-requirements) must be a system running one of the following UNIX operating systems: Linux (Red Hat, Debian, CentOS), macOS, or any of the BSDs. Windows is not supported for the Control Machine.
* Python version 2.6 or higher

> **Notes:**
  - Currently, the Ansible Module requires Full Cluster Administrator access.
  - Before using this task, refer to the [Setup](../setup.md) and [How to Use](../how-to-use.md) sections of this guide.

## Ansible Variables
[top](#task-cohesity-file-restore-operation)

The following is a list of variables and the configuration expected when leveraging this task in your playbook.  For more information on these variables, see [Cohesity Protection Job](/modules/cohesity_job.md?id=syntax).
```yaml
cohesity_restore_file:
  state: "present"
  name: ""
  environment: "Physical"
  job_name: ""
  endpoint: ""
  backup_id: ""
  files: ""
  wait_for_job: True
  wait_minutes: 10
  overwrite: True
  preserve_attributes: True
  restore_location: ""
```
## Customize Your Playbooks
[top](#task-cohesity-file-restore-operation)

This example shows how to include the Cohesity Ansible Role in your custom playbooks and leverage this task as part of the delivery.

### Restore a File from most recent snapshot
[top](#task-cohesity-file-restore-operation)

This is an example playbook that creates a new File Recovery Operation for Protection Job. (Remember to change it to suit your environment.)
> **Notes:**
  - Before using these example playbooks, refer to the [Setup](../setup.md) and [How to Use](../how-to-use.md) sections of this guide.
  - This example requires that the endpoint matches an existing Protection Source.  See [Task: Cohesity Protection Source Management](tasks/source.md).
  - This example requires that the Protection job exists and has been run at least once.  See [Task: Cohesity Protection Job Management](tasks/job.md).

```yaml
---
  - hosts: workstation
    # => Please change these variables to connect
    # => to your Cohesity Cluster
    vars:
        var_cohesity_server: cohesity_cluster_vip
        var_cohesity_admin: admin
        var_cohesity_password: admin
        var_validate_certs: False
        var_cohesity_restore_name: "Ansible Test File Restore"
        var_cohesity_endpoint: 
        var_cohesity_job_name:
        var_cohesity_files:
    roles:
      - cohesity.ansible
    tasks:
      - name: Restore Files
        include_role:
            name: cohesity.ansible
            tasks_from: restore_file
        vars:
            cohesity_server: "{{ var_cohesity_server }}"
            cohesity_admin: "{{ var_cohesity_admin }}"
            cohesity_password: "{{ var_cohesity_password }}"
            cohesity_validate_certs: "{{ var_validate_certs }}"
            cohesity_restore_file:
                name: "{{ var_cohesity_restore_name }}"
                endpoint: "{{ var_cohesity_endpoint }}"
                environment: "Physical"
                job_name: "{{ var_cohesity_job_name }}"
                files: "{{ var_cohesity_files }}"
                wait_for_job: True

```


## How the Task Works
[top](#task-cohesity-file-restore-operation)

The following information is copied directly from the included task in this role.  The source file is located at the root of this role in `/tasks/restore_file.yml`.
```yaml
---
- name: "Cohesity Recovery Job: Restore a set of files"
  cohesity_restore_file:
    cluster: "{{ cohesity_server }}"
    username: "{{ cohesity_admin }}"
    password: "{{ cohesity_password }}"
    validate_certs: "{{ cohesity_validate_certs }}"
    state:  "{{ cohesity_restore_file.state | default('present') }}"
    name: "{{ cohesity_restore_file.name | default('') }}"
    environment: "{{ cohesity_restore_file.environment | default('Physical') }}"
    job_name: "{{ cohesity_restore_file.job_name | default('') }}"
    endpoint: "{{ cohesity_restore_file.endpoint | default('') }}"
    backup_id: "{{ cohesity_restore_file.backup_id | default('') }}"
    file_names: "{{ cohesity_restore_file.files | default('') }}"
    wait_for_job: "{{ cohesity_restore_file.wait_for_job | default('yes') }}"
    wait_minutes: "{{ cohesity_restore_file.wait_minutes | default(10) }}"
    overwrite: "{{ cohesity_restore_file.overwrite | default('yes') }}"
    preserve_attributes: "{{ cohesity_restore_file.preserve_attributes | default('yes') }}"
    restore_location: "{{ cohesity_restore_file.restore_location | default('') }}"
  tags: always

```
