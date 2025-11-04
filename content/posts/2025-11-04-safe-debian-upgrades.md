---
title: "Safe Debian upgrades"
date: "2025-11-04"
slug: "safe-debian-upgrades"
---

## Goal

Upgrade packages while avoiding unintended kernel upgrades or package breakage.

### Quick checklist

1. Update package lists: `sudo apt update`  
2. Simulate upgrade: `apt -s upgrade`  
3. Simulate full upgrade: `apt -s full-upgrade`  
4. Perform upgrade: `sudo apt upgrade`

Always test in a VM if possible. Keep backups of critical configs.
