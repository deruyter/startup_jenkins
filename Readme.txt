##############################
#  Startup kit for Jenkins   #
##############################

1 - Configuration
------------------


To use this package, you need to copy and instantiate the script
admin/aci_config_template into aci_config.sh where :

  ACI_DOMAIN_NAME= [ Your domain name if any ]
  ACI_HOST=[ Host machine name (i.e. localhost) ]
  ACI_USER=[ username that launch ACI ]
  ACI_URL=[ ACI URL ]
  ACI_PORT= [ Port on which ACI should be accessed from web browser ]
  ACI_SSH_PORT= [ Port on which ACI should be accessed for ssh accesses ]
  JAVA= [ How to access Java ]


2 - Using the package
---------------------

 a - To launch Jenkins
 =====================
 
 ./safe_start.sh
 
 This script check that you are on the right machine according to the
 configuration .
 It also put all project on pause mode to avoid cold restart of all jobs.
 
 b - To stop Jenkins
 ====================
 
  ./safe_stop.sh
  
 c - To re-activate Jobs
 =======================
  
   ./safe_activate.sh
   
  This script reactivate jobs
  
  
  
