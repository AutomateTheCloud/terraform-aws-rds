# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A suffix for the final snapshot's name, so that a database created again with the
# same identifier does not collide with the snapshot of the one deleted before it. The
# keepers are the identifier and every input that replaces the instance (its ForceNew
# arguments in provider 6.67.0, less username and snapshot_identifier, which
# ignore_changes keeps from replacing it), so a replacement gets a new suffix: otherwise
# the replaced instance's final snapshot takes the name, and deleting the new instance
# fails because the snapshot exists.
resource "random_id" "final_snapshot" {
  byte_length = 4

  keepers = {
    identifier               = var.identifier
    engine                   = var.engine
    db_name                  = var.db_name
    nchar_character_set_name = var.nchar_character_set_name
    kms_key_id               = var.kms_key_id
  }
}
