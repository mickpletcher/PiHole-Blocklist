# Curated Pi-hole Lists

Review the profile scope before subscribing. Device and policy profiles deliberately block services beyond general advertising, tracking, and malware protection.

## Curated Output URLs

| Output | Raw URL |
|---|---|
| Balanced blocklist | https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist.txt |
| Strict blocklist | https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist-strict.txt |
| Device blocklist | https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist-device.txt |
| Policy blocklist | https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist-policy.txt |
| Project allowlist | https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-whitelist.txt |

## Inventory Summary

| Metric | Count |
|---|---:|
| Total source rows | 45 |
| Enabled source rows | 19 |
| Disabled source rows | 26 |
| Categories | 14 |

## Profiles

| Profile | Purpose | Source count |
|---|---|---:|
| Balanced | Default security, privacy, advertising, and tracking protection. | 2 |
| Strict | Balanced plus OISD Big for broader blocking. | 3 |
| Device | Opt-in device and service-specific restrictions. | 11 |
| Policy | Opt-in piracy, shortener, bypass, fake-news, and SafeSearch policy restrictions. | 5 |

## Suspicious / Spam

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| false | None | Moderate | Auto | KADhosts | https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt |
| false | None | Moderate | Auto | FadeMind Spam Extras | https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts |
| false | None | Moderate | Auto | w3kbl | https://v.firebog.net/hosts/static/w3kbl.txt |
| false | None | Moderate | Domains | Matomo Referrer Spam Blacklist | https://raw.githubusercontent.com/matomo-org/referrer-spam-blacklist/master/spammers.txt |
| false | None | Moderate | Hosts | Someone Who Cares Hosts Zero | https://someonewhocares.org/hosts/zero/hosts |
| false | None | Moderate | Auto | RooneyMcNibNug SNAFU | https://raw.githubusercontent.com/RooneyMcNibNug/pihole-stuff/master/SNAFU.txt |

## Advertising

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| false | None | Moderate | Hosts | AdAway | https://adaway.org/hosts.txt |
| false | None | Moderate | Auto | HoSTS AdBlock | https://v.firebog.net/hosts/AdguardDNS.txt |
| false | None | Moderate | Hosts | Peter Lowe's Ad and tracking server list | https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext |
| false | None | Moderate | Hosts | FadeMind Ad Extras | https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts |
| false | None | Moderate | Domains | Disconnect.me Simple Ad | https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt |

## Tracking

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| false | None | Moderate | Domains | Disconnect.me Simple Tracking | https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt |
| false | None | Moderate | Auto | EasyPrivacy | https://v.firebog.net/hosts/Easyprivacy.txt |
| false | None | Moderate | Hosts | FadeMind Tracking Extras | https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts |
| false | None | Moderate | Domains | CNAME Cloaking Blocklist | https://raw.githubusercontent.com/nextdns/cname-cloaking-blocklist/master/domains |

## Malicious

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| true | Balanced, Strict | Moderate | Adblock | Threat Intelligence Feeds | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt |
| false | None | Moderate | Domains | Phishing URL Blocklist | https://phishing.army/download/phishing_army_blocklist_extended.txt |
| false | None | Moderate | Hosts | URLhaus | https://urlhaus.abuse.ch/downloads/hostfile/ |
| false | None | Moderate | Hosts | ThreatFox | https://threatfox.abuse.ch/downloads/hostfile/ |
| false | None | Moderate | Auto | RPiList Phishing | https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/Phishing-Angriffe |
| false | None | Moderate | Auto | RPiList Malware | https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/malware |

## Fake News

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| true | Policy | High | Hosts | StevenBlack Fake News | https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-only/hosts |

## Device Trackers

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| true | Device | High | Auto | RPiList Amazon Video | https://raw.githubusercontent.com/RPiList/specials/master/Internet%20Services/Amazon-Video |
| true | Device | High | Auto | RPiList Apple Music | https://raw.githubusercontent.com/RPiList/specials/master/Internet%20Services/Apple-Music |
| true | Device | High | Auto | RPiList Apple iCloud | https://raw.githubusercontent.com/RPiList/specials/master/Internet%20Services/Apple-iCloud |
| true | Device | High | Auto | RPiList Apple iTunes | https://raw.githubusercontent.com/RPiList/specials/master/Internet%20Services/Apple-iTunes |
| true | Device | High | Auto | RPiList MS Office Telemetry | https://raw.githubusercontent.com/RPiList/specials/master/Blocklisten/MS-Office-Telemetry |
| true | Device | High | Hosts | Hagezi Windows / Office Native Tracker | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/hosts/native.winoffice.txt |
| true | Device | High | Hosts | Hagezi TikTok Native Tracker | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/hosts/native.tiktok.txt |
| true | Device | High | Auto | RPiList Microsoft Office 365 | https://raw.githubusercontent.com/RPiList/specials/master/Internet%20Services/Microsoft%20Office%20365 |

## Smart TV / IoT

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| true | Device | High | Auto | Perflyst SmartTV | https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt |
| true | Device | High | Hosts | Hagezi Samsung Native Tracker | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/hosts/native.samsung.txt |
| true | Device | High | Hosts | Hagezi LG WebOS Native Tracker | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/hosts/native.lgwebos.txt |

## Fake DNS / DynDNS

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| false | None | High | Adblock | Hagezi DynDNS Blocklist | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/dyndns.txt |
| false | None | High | Adblock | Hagezi Badware Hoster | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/hoster.txt |

## Piracy

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| true | Policy | High | Adblock | Hagezi Anti-Piracy | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/anti.piracy.txt |

## URL Shorteners

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| true | Policy | High | Adblock | Hagezi URL Shortener Blocklist | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/urlshortener.txt |

## Encrypted DNS / VPN Bypass

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| true | Policy | High | Adblock | Hagezi Encrypted DNS/VPN/TOR Bypass | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/doh-vpn-proxy-bypass.txt |

## Hagezi DNS Blocklists (Multi-category)

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| true | Balanced, Strict | Moderate | Adblock | Hagezi Pro | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt |
| false | None | High | Adblock | Hagezi Fake DNS Blocklist | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/fake.txt |
| false | None | High | Adblock | Hagezi Pop-Up Ads | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/popupads.txt |
| true | Policy | High | Adblock | Hagezi SafeSearch Not Supported | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/nosafesearch.txt |
| false | None | High | AdblockTld | Hagezi Spam TLDs | https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/spam-tlds-adblock.txt |

## OISD

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| true | Strict | Moderate | Auto | OISD Big | https://big.oisd.nl/ |

## Other / Unified

| Enabled | Profiles | Risk | Format | Source | URL |
|---|---|---|---|---|---|
| false | None | Moderate | Hosts | StevenBlack Unified Hosts | https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts |
