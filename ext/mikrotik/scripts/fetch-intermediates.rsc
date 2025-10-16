# dontrequireperms=yes
# policy=ftp,read,write,policy,test,sensitive

:local res [/tool/fetch url="https://letsencrypt.org/certificates/" as-value output=user]
:local certificates ($res->"data")

:do {
    :local nextlinkbegin [:find $certificates "<a href=\"" 0]
    :if ($nextlinkbegin < 0) do={
        :put "No more links found"
        :set certificates ""
    } else={
        :local nextlinkend [:find $certificates "\">" $nextlinkbegin]
        :local nextlink [:pick $certificates ($nextlinkbegin + 9) $nextlinkend]
        :set certificates [:pick $certificates $nextlinkend [:len $certificates]]

        # Minimal URL path resolver...
        :if ([:pick $nextlink 0 1] = "/") do={
            :set nextlink ("https://letsencrypt.org" . $nextlink)
        } else={
            :if ([:find $nextlink "://" 0] < 0) do={
                :set nextlink ("https://letsencrypt.org/certificates/" . $nextlink)
            }
        }

        :if ([:pick $nextlink ([:len $nextlink] - 4) [:len $nextlink]] = ".pem") do={
            :if ([:find $nextlink "-cross" 0] < 0) do={
                :if ([:find $nextlink "/letsencryptauthorityx" 0] < 0) do={
                    :local foundcerts [/certificate/find name=$nextlink]
                    :if ([:len $foundcerts] = 0) do={
                        :put "Downloading $nextlink"
                        :do {
                            /file/remove tmpfs-scratch/intermediates-cert.pem
                            :delay 1s
                        } on-error={}
                        /tool/fetch url=$nextlink dst-path=tmpfs-scratch/intermediates-cert.pem
                        :delay 1s
                        /certificate/import file-name=tmpfs-scratch/intermediates-cert.pem name=$nextlink trusted=yes
                        :delay 1s
                    } else={
                        :put "Skipping already downloaded $nextlink"
                    }
                } else={
                    :put "Skipping obsolete letsencryptauthorityx# certificate $nextlink"
                }
            } else={
                :put "Skipping cross-signed certificate $nextlink"
            }
        }
    }
} while ([:len $certificates] > 0)

