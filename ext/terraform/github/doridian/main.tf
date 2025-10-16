locals {
  repositores = {
    wsvpn = {
      description = "VPN over WebSocket and WebTransport"
      required_checks = [
        "lint (macos-latest)",
        "lint (ubuntu-latest)",
        "lint (windows-latest)",
        "test (macos-latest)",
        "test (ubuntu-latest)",
      ]
    }
    water = {
      description = "A simple TUN/TAP library written in native Go."
      required_checks = [
        "lint (macos-latest)",
        "lint (ubuntu-latest)",
        "lint (windows-latest)",
        "test (macos-latest)",
        "test (ubuntu-latest)",
      ]
    }
    jsip-wsvpn        = {}
    wsvpn-js          = {}
    query-finder      = {}
    factorio-fox-todo = {}
    slimfat           = {}
    tracething        = {}
    jsip = {
      description = "TCP/UDP/ICMP/IP/Ethernet stack in pure TypeScript."
    }
    LuaJS = {
      description = "Lua VM running in Javascript (using emscripten)"
    }
    HomeAssistantMQTT = {}
    streamdeckpi      = {}
    go-streamdeck     = {}
    go-haws           = {}
    gitbackup         = {}
    BambuProfiles = {
      description = "Profiles for Bambu Lab printers"
    }
    OpenBambuAPI = {
      description = "Bambu API docs"
    }
    flippertools = {
      visibility = "private"
    }
    # Forks
    qmk_firmware = {
      description       = "Open-source keyboard firmware for Atmel AVR and Arm USB families"
      branch_protection = false
    }
    factorio-pause-commands = {
      description       = "Factorio mod to add pause and unpause commands"
      branch_protection = false
    }
    gopacket = {
      description       = "Provides packet processing capabilities for Go"
      branch_protection = false
    }
    carvera-pendant = {
      required_checks = [
        "lint_and_build",
      ]
    }
    karalabe_hid = {
      description = "Gopher Interface Devices (USB HID)"
    }
    superfan = {}
    foxDNS = {
      description = "DNS server written in Golang"
    }
    foxIngress = {
      description = "HTTP(S)/QUIC SNI/Host router"
    }
    fadumper = {
      required_checks = [
        "lint_and_build",
      ]
    }
    DarkSignsOnline = {
      homepage_url = "https://darksignsonline.com"
    }
    NetDAQ = {}
    aurbuild = {
      description = "Automated AUR builds so my laptop doesn't try to take off"
    }
    fwui = {
      description = "Framework 16 LED matrix UI for expansion card status"
    }
    kbidle = {}
    node-single-instance = {
      description = "Check if an instance of the current application is running or not."
    }
    oauth-jit-radius = {}
    panon = {
      description    = "An Audio Visualizer Widget in KDE Plasma (works in KDE Plasma 6)"
      default_branch = "6.x.x"
    }
    panon-effects = {}
    qmk_hid = {
      description = "Commandline tool for interacting with QMK devices over HID"
    }
    ustreamer = {
      description  = "µStreamer - Lightweight and fast MJPEG-HTTP streamer"
      homepage_url = "https://pikvm.org"
    }
    viauled = {}
    inputmodule-rs = {
      description = "Framework Laptop 16 Input Module SW/FW"
    }
    mkinitcpio-sd-pcr8lock-hook = {}
    dotfiles                    = {}
    libnss_igshim               = {}
    linux-cachyos-dori = {
      description       = "CachyOS kernel with my own patches :3"
      branch_protection = false
    }

    python-ax1200i = {}
    tanqua         = {}

    DroneControl = {
      visibility = "private"
    }

    froxlor-system = {}
    pdnstiny       = {}

    kanidm = {
      description    = "Kanidm: A simple, secure and fast identity management platform"
      default_branch = "master"
    }
  }
}

# tfimp() { tofu import "module.repo[\"$1\"].github_repository.repo" "$1"; tofu import "module.repo[\"$1\"].github_branch_protection.main[0]" "$1:main"; }

module "repo" {
  for_each = local.repositores

  source = "../modules/repo"
  repository = merge({
    name         = each.key
    description  = ""
    homepage_url = ""

    visibility = "public"

    required_checks   = []
    branch_protection = true

    pages = null
  }, each.value)
}
