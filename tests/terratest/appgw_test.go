package test

import (
	"fmt"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"path/filepath"
	"testing"
	"time"
	"crypto/tls"
)

//Testing the secure-file-transfer Module
func TestTerraformAzureAppGW(t *testing.T) {
	t.Parallel()

	//subscriptionID := "e6b5053b-4c38-4475-a835-a025aeb3d8c7"
	// Terraform plan.out File Path
	exampleFolder := test_structure.CopyTerraformFolderToTemp(t, "../..", "examples/complete")
	planFilePath := filepath.Join(exampleFolder, "plan.out")

	expectedAppGatewayName := "APPGW-TF-TEST-01"

	terraformPlanOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,

		// Variables to pass to our Terraform code using -var options
		VarFiles: []string{"for_terratest.tfvars"},

		//Environment variables to set when running Terraform

		// Configure a plan file path so we can introspect the plan and make assertions about it.
		PlanFilePath: planFilePath,
	})

	// Run terraform init plan and show and fail the if there are any errors
	terraform.InitAndPlanAndShowWithStruct(t, terraformPlanOptions)

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformPlanOptions)

	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformPlanOptions)
	appGatewayName := terraform.Output(t, terraformPlanOptions, "appgw_name")

	assert.Contains(t, appGatewayName, expectedAppGatewayName)

	// website::tag::3:: Run `terraform output` to get the values of output variables
	//appgwid := terraform.Output(t, terraformOptions, "appgw_id")
	//appgwname := terraform.Output(t, terraformOptions, "appgw_name")
	publicIp := terraform.Output(t, terraformPlanOptions, "appgw_public_ip_address")

	// It can take a few minutes for the deployment to be ready
	maxRetries := 30
	timeBetweenRetries := 5 * time.Second
	url := fmt.Sprintf("https://%s", publicIp)

	// Verify that we get back a 200 OK with the output

    tlsConfig := &tls.Config{InsecureSkipVerify: true}
	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		url,
		tlsConfig,
		maxRetries,
		timeBetweenRetries,
		func(statusCode int, body string) bool {
			return statusCode == 200
		},
	)

}
