## 1. Backup Tools Image

- [ ] 1.1 Create `images/backup-tools/Dockerfile` installing `rclone` and `rustic`
- [ ] 1.2 Build and push the image to `ghcr.io/nimser/homelab-backup-tools`
- [ ] 1.3 Add backup image build instructions to the root `README.md`

## 2. Rammus: Warm Sync (rclone)

- [ ] 2.1 Generate SSH keys for SFTP authentication between `rammus` and `karma`
- [ ] 2.2 Create plaintext `backup-rclone-config.yaml` with the SFTP backend configuration and encrypt with SOPS
- [ ] 2.3 Create `apps/base/soft-serve/backup-cronjob.yaml` containing the 15-minute `rclone sync` to `karma:rammus/soft-serve`
- [ ] 2.4 Add SOPS secret reference to `apps/rammus/soft-serve/kustomization.yaml`
- [ ] 2.5 Ensure the Soft Serve PVC is mounted with `readOnly: true` and `concurrencyPolicy: Forbid` in the CronJob

## 3. Karma: Cold Backup (rustic)

- [ ] 3.1 Create plaintext `backup-rustic-env.yaml` with idrive e2 AWS credentials and repository password and encrypt with SOPS
- [ ] 3.2 Ensure the RustFS app on `karma` provides an SFTP server or SSH daemon with the correct authorized keys
- [ ] 3.3 Create a new application path `apps/base/soft-serve-backup/` containing the 6-hour rustic CronJob targeting the `rammus/soft-serve` local directory
- [ ] 3.4 Configure the rustic CronJob to run `rustic backup`, followed by `rustic forget` and `rustic prune`
- [ ] 3.5 Create `apps/karma/soft-serve-backup/kustomization.yaml` referencing the base and the SOPS secret
- [ ] 3.6 Add `soft-serve-backup` to `apps/karma/kustomization.yaml`

## 4. Verification and Documentation

- [ ] 4.1 Apply changes and wait for FluxCD reconciliation on both clusters
- [ ] 4.2 Manually trigger the rclone CronJob on `rammus` and verify data appears in `/mnt/rustfs/rammus/soft-serve` on `karma`
- [ ] 4.3 Manually trigger the rustic CronJob on `karma` and verify snapshots appear in the idrive e2 bucket
- [ ] 4.4 Update the root `README.md` with a high-level overview of the 3-2-1 backup strategy (rclone to RustFS, rustic to idrive e2)
