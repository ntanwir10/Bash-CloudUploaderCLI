# Bash based CloudUploaderCLI with AWS

#### This project is inspired by @learn-to-cloud guide by @madebygps. Check it out [Learn to cloud](https://learntocloud.guide/phase1/#capstone-project-clouduploader-cli)

`Create a bash-based CLI tool that allows users to quickly upload files to a specified cloud storage solution, providing a seamless upload experience similar to popular storage services.`

Your tool should be able to upload a file: `clouduploader /path/to/file.txt`

### Steps:

**1. Create a GitHub Repo:**

- [X] Set up a repository for your project.
-  [x] Use branches and commit your code often.
-  [x] Utilize git commands (git init, git add, git commit, git branch, git push, etc.).

**2.Setup & Authentication:**

-  [x] Choose a cloud provider (e.g., AWS S3, Google Cloud Storage, Azure Blob Storage).
-  [x] Set up authentication (e.g., az login for Azure).
-  [x] Use secure methods for handling credentials.
   -  [x] Avoid hardcoding credentials directly into the script.
   -  [ ] Store credentials in environment variables or configuration files with restricted access.
   -  [x] Utilize cloud provider's secure authentication methods (e.g., IAM roles for AWS, service principals for Azure).

**3.CLI Argument Parsing:**

-  [ ] Use bash's built-in `$1`, `$2`, etc., to parse command-line arguments.
-  [ ] `$1` could be the filename or path.
-  [ ] Optionally, allow additional arguments like target cloud directory, storage class, or any other cloud-specific attributes.
-  [ ] Validate and handle different types of input.\\
-  [ ] Check if the provided file path is valid and accessible.
-  [ ] Ensure that additional arguments meet expected formats and values.
-  [ ] Provide meaningful error messages for incorrect or missing inputs

**4.File Check:**

-  [ ] Before uploading, check if the file exists using `[ -f $FILENAME ]`.
-  [ ] Provide feedback if the file is not found.

**5.File Upload:**

-  [ ] Use the cloud provider's CLI to upload the file.
-  [ ] Implement error handling to manage potential issues during upload.

**6.Upload Feedback:**

-  [ ] On successful upload, provide a success message.
-  [ ] If there's an error, capture the error message and display it to the user.

**7.Advanced Features (Optional but recommended):**

-  [ ] Add a progress bar or percentage upload completion using tools like `pv`.
-  [ ] Provide an option to generate and display a shareable link post-upload.
-  [ ] Enable file synchronization -- if the file already exists in the cloud, prompt the user to overwrite, skip, or rename.
-  [ ] Integrate encryption for added security before the upload.

**8.Documentation:**

-  [ ] Write a README.md file explaining how to set up, use, and troubleshoot the tool.
-  [ ] Include a brief overview, prerequisites, usage examples, and common issues.

**9.Distribution:**

-  [ ] Package the script for easy distribution and installation. You can even provide a simple installation script or instructions to add it to the user's `$PATH`.

## Things you should be able familiar with at the end of this phase[​](https://learntocloud.guide/phase1/#things-you-should-be-able-familiar-with-at-the-end-of-this-phase)

### Commands[​](https://learntocloud.guide/phase1/#commands)

-   Navigate with the `cd` command.
-   How to list the contents of a directory and using the `ls` command.
-   Create, copy, move, rename, directories and files
    with `mkdir`, `cp`, `rm`, and `touch` commands.
-   Find things with `locate`, `whereis`, `which`, and `find` commands.
-   Understand how to learn more about commands with the `which`, `man`,
    and `--help` commands.
-   Familiar with finding logs details in `/var/log`
-   How to display the contents of a file
    with `cat`, `less`, `more`, `tail`, `head`.
-   Filtering with `grep` and `sed`.
-   Redirection of standard input, output and error with `>` operator
    and `tee` command.
-   How to use pipelines with the `|` operator.
-   Manipulate files with `nano` or `vim`.
-   Install and uninstall packages. Depends on distro, debian based
    use `apt`.
-   Control permissions with `chown`, `chgrp`, `chmod` commands.
-   Creating users and the `sudo` command.
-   Process management with `ps`, `top`, `nice`, `kill`
-   Manage environment aud user defined variables
    with `env`, `set`, `export` commands.
-   Add directories to your `PATH`.
-   Compression and archiving with `tar`, `gzip`, `gunzip`.
-   How to access a Linux server with `ssh`.

### Networking[​](https://learntocloud.guide/phase1/#networking)

Concepts you should be familiar with.

-   OSI Model
-   IP Addresses
-   MAC Addresses
-   Routing and Switching
-   TCP/IP
-   TCP and UDP
-   DNS
-   VPN tunneling
-   TLS and SSL

### Bash Scripting[​](https://learntocloud.guide/phase1/#bash-scripting)

-   What is a shell?
-   What is Bash?
-   Why does a script have to start with #!?
-   What is a variable and how to use them
-   How to accept user input
-   How to execute a script