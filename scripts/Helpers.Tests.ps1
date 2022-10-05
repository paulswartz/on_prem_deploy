BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

Describe "ContainerStack" {
    It "Generates well-formatted YAML" {
        $rawOutput = ContainerStack `
            -Service "service-test" `
            -Image "image" `
            -SplunkToken "token" `
            -SplunkUrl "splunk.com" `
            -SplunkIndex "idx"
        $output = $rawOutput | ConvertFrom-Yaml
        $output | Should -Not -Be $null
        $output.version | Should -Be "3.7"
        $container = $output.services.container
        $container.image | Should -Be "image"
        $rawOutput | Should -Not -Match "environment:"
        $rawOutput | Should -Not -Match "ports:"
        $container.logging.driver | Should -Be "splunk"
        $container.logging.options["splunk-token"] | Should -Be "token"
        $container.logging.options["splunk-url"] | Should -Be "splunk.com"
        $container.logging.options["splunk-index"] | Should -Be "idx"
        $container.logging.options["splunk-source"] | Should -Be "service-test"
        $container.deploy.resources.limits.cpus | Should -Be "0.25"
        $container.deploy.resources.limits.memory | Should -Be "256M"
    }

    It "Includes ports if configured" {
        $output = ContainerStack `
            -Service "service-test" `
            -Image "image" `
            -SplunkToken "token" `
            -SplunkUrl "splunk.com" `
            -SplunkIndex "idx" `
            -TaskPort "4000" `
        | ConvertFrom-Yaml
        $output.services.container.ports | Should -HaveCount 1
        $output.services.container.ports[0] | Should -Be "4000:4000"
    }

    It "Includes multiple ports on separate lines" {
        $output = ContainerStack `
            -Service "service-test" `
            -Image "image" `
            -SplunkToken "token" `
            -SplunkUrl "splunk.com" `
            -SplunkIndex "idx" `
            -TaskPort "4000 5000" `
        | ConvertFrom-Yaml
        $output.services.container.ports | Should -HaveCount 2
        $output.services.container.ports[0] | Should -Be "4000:4000"
        $output.services.container.ports[1] | Should -Be "5000:5000"
    }

    It "Includes environment variables if provided" {
        $output = ContainerStack `
            -Service "service-test" `
            -Image "image" `
            -Environment @{
              KEY = "value`nvalue2"
              KEY2 = "single line value"
            } `
            -SplunkToken "token" `
            -SplunkUrl "splunk.com" `
            -SplunkIndex "idx" `
        | ConvertFrom-Yaml
        $output | Should -Not -Be $null
        $container = $output.services.container
        $container.environment.KEY | Should -Be "value`nvalue2"
        $container.environment.KEY2 | Should -Be "single line value"
    }

    It "Can use environment variables converted from JSON" {
        $jsonParsed = @"
{"KEY": "value\nvalue2"}
"@ | ConvertFrom-Json
        $output = ContainerStack `
            -Service "service-test" `
            -Image "image" `
            -Environment $jsonParsed.psobject.Properties `
            -SplunkToken "token" `
            -SplunkUrl "splunk.com" `
            -SplunkIndex "idx" `
        | ConvertFrom-Yaml
        $output | Should -Not -Be $null
        $container = $output.services.container
        $container.environment.KEY | Should -Be "value`nvalue2"
    }

    It "Does not include an environment key when provided empty JSON" {
        $jsonParsed = "{}" | ConvertFrom-Json
        $rawOutput = ContainerStack `
            -Service "service-test" `
            -Image "image" `
            -Environment $jsonParsed.psobject.Properties `
            -SplunkToken "token" `
            -SplunkUrl "splunk.com" `
            -SplunkIndex "idx"
        $rawOutput | Should -Not -Match "environment:"
    }
}