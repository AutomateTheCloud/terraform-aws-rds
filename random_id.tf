# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A suffix for the final snapshot's name, so that a database created again with the
# same identifier does not collide with the snapshot of the one deleted before it.
resource "random_id" "final_snapshot" {
  byte_length = 4

  keepers = {
    identifier = var.identifier
  }
}
