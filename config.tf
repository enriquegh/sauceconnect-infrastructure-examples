terraform {
  backend "remote" {
    organization = "enriquegh"

    workspaces {
      name = "enriquegh-workspace"
    }
  }
}
