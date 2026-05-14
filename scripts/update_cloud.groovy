import jenkins.model.*
import hudson.plugins.ec2.*

def instance = Jenkins.instance

def cloud = instance.clouds.getByName("gami2023")

if (cloud == null) {
    println("Cloud not found")
    return
}

def latestAmi = binding.variables['LATEST_AMI']

println("Latest AMI: ${latestAmi}")

cloud.templates.each { template ->

    if (template.description == "goldenami") {

        println("Updating template AMI...")

        template.ami = latestAmi

        println("Updated AMI to: ${latestAmi}")
    }
}


instance.save()

println("Jenkins cloud configuration saved")
