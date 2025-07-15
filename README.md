[![minimum 4D version](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/CGareau/dd2aa26e5b6c4152e80e7d3d09f2486a/raw/version_webadmin.json)]()
![maintenance-status](https://img.shields.io/badge/maintenance-actively--developed-brightgreen.svg)
<br>
[![support ubuntu](https://img.shields.io/badge/ubuntu-E95420.svg?style=flat-square&logo=ubuntu&labelColor=E95420&logoColor=white)]()
[![support mac](https://img.shields.io/badge/macOS-000000.svg?style=flat-square&logo=apple&labelColor=000000&logoColor=white)]()
[![support windows](https://img.shields.io/badge/windows-0078D6.svg?style=flat-square&logo=MODX&logoColor=white)]()

# Tools 4D

![WebAdmin](https://blog.4d.com/wp-content/uploads/2023/03/tool4d_banner.png)

In the development industry, CI/CD has become a standard practice. With each code modification, automated actions such as testing, compilation, building, delivery, and sometimes deployment are generated to ensure the code is high quality and easily integrated into the existing system.

These actions require a tool to execute the necessary code. As 4D developers, we decided to provide a free tool that allows developers to execute elementary actions. This tool is called **tool4d**, and it streamlines the process of executing necessary actions within the 4D environment.

This new application is mainly dedicated to being integrated into CI/CD pipelines. The main goal of **tool4d** is, therefore, to execute 4D code with a minimal instruction set, a minimal memory footprint, and a minimum size. The **tool4d** application can be seen as a subset of the 4D application.

---

## What is tool4d?

**tool4d** is a command-line tool to run 4D code without the 4D user interface. It allows you to automate tasks such as:

- Running 4D methods
- Executing JavaScript code inside the 4D environment
- Running 4D queries or commands
- Interacting with 4D databases

This lightweight tool is ideal for embedding in continuous integration pipelines or other automated workflows where running 4D code programmatically is necessary.

---

## Features

- **Minimal size and footprint**: tool4d is designed to be as lightweight as possible.
- **Cross-platform support**: runs on Ubuntu, macOS, and Windows.
- **Simple CLI interface**: easy to integrate into scripts and automation tools.
- **Extensible**: supports running both 4D and JavaScript code inside 4D.

---

## Installation

You can download the latest version of **tool4d** from the [4D blog](https://blog.4d.com/a-tool-for-4d-code-execution-in-cli/).

Installation steps depend on your platform. Typical usage is to extract the binary and place it in your system PATH or your CI/CD runner environment.

---

## Basic Usage

**tool4d** is very suitable for building tasks such as unit tests or compilations.
Here is an example of a small project named compileThisProject compiling another project:

```bash
/Applications/tool4d.app/Contents/MacOS/tool4d --project "/Users/Me/compileThisProject/Project/compileThisProject.4DProject" --user-param "/Users/Me/Test/Project/Test.4DProject"