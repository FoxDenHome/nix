# policy=read,write,policy,test
# schedule=00:01:00

:global logputinfo
:global logputerror

:local needrestart ([:len [/file/find name=container-restart-all]] > 0)
:local needupdate ([:len [/file/find name=container-update-all]] > 0)
:local clearrestart $needrestart
:local clearupdate $needupdate
:local hidestartok true
:local maxtries 0

:if ($needupdate) do={
  $logputinfo ("Need update!")
  :set needrestart true
}

:if ($needrestart) do={
  $logputinfo ("Need restart!")
}

/container
:foreach ct in=[find] do={
  :local ctneedstop $needrestart
  :if (![get $ct running]) do={
    :set ctneedstop true
  }

  :if ($ctneedstop) do={
    $logputinfo ("STOPPING container with interface " . [get $ct interface])
    stop $ct

    :set maxtries 50
    :while ($maxtries > 0) do={
      :delay 100ms
      :set maxtries ($maxtries - 1)
      :if ([get $ct stopped]) do={
        :set maxtries -999
      }
    }
    :if ($maxtries != -999) do={
      $logputerror ("FAILED STOPPING container with interface " . [get $ct interface])
    } else={
      $logputinfo ("STOPPED container with interface " . [get $ct interface])
    }
  }

  :if ([get $ct stopped]) do={
    $logputinfo ("STARTING container with interface " . [get $ct interface])

    :if ($needupdate) do={
      :local ctinfo [get $ct]

      $logputinfo ("UPDATING/REMOVE container with interface " . ($ctinfo->"interface"))
      remove $ct

      $logputinfo ("UPDATING/ADD container with interface " . ($ctinfo->"interface"))
      add interface=($ctinfo->"interface") \
        logging=($ctinfo->"logging") \
        mounts=($ctinfo->"mounts") \
        start-on-boot=($ctinfo->"start-on-boot") \
        remote-image=($ctinfo->"repo")

      :set ct ([find interface=($ctinfo->"interface")]->0)

      :set maxtries 600
      :while ($maxtries > 0) do={
        :delay 100ms
        :set maxtries ($maxtries - 1)
        :if ([get $ct stopped]) do={
          :set maxtries -999
        }
      }
      :if ($maxtries != -999) do={
        $logputerror ("FAILED UPDATING container with interface " . ($ctinfo->"interface"))
      } else={
        $logputinfo ("UPDATED container with interface " . ($ctinfo->"interface"))
      }
    }

    :set hidestartok false
    start $ct
  }

  :set maxtries 50
  :while ($maxtries > 0) do={
    :delay 100ms
    :set maxtries ($maxtries - 1)
    :if ([get $ct running]) do={
      :set maxtries -999
    }
  }
  :if ($maxtries != -999) do={
    $logputerror ("FAILED STARTING container with interface " . [get $ct interface])
    :set clearrestart false
  } else={
    :if (!$hidestartok) do={
      $logputinfo ("STARTED container with interface " . [get $ct interface])
    }
  }
}

:if ($clearrestart) do={
  /file/remove container-restart-all
  $logputinfo ("Cleared container-restart-all")
}

:if ($clearupdate) do={
  /file/remove container-update-all
  $logputinfo ("Cleared container-update-all")
}
