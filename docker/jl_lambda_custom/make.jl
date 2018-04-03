using AWSCore 
using AWSS3
using AWSLambda 

JL_VERSION_BASE="0.6"
JL_VERSION_PATCH="2"
JL_VERSION="$JL_VERSION_BASE.$JL_VERSION_PATCH"

image_name = "octech/$(replace(basename(pwd()), "_", "")):$JL_VERSION"

lambda_name = basename(pwd())

source_bucket = "octech.com.au.ap-southeast-2.awslambda.jl.deploy"

base_zip = "$(lambda_name)_$(VERSION)_$(AWSLambda.aws_lamabda_jl_version).zip"

if length(ARGS) == 0 || ARGS[1] == "build"
cp("../../src/AWSLambda.jl", "AWSLambda.jl"; remove_destination=true)
run(`docker build
        --build-arg JL_VERSION_BASE=$JL_VERSION_BASE
        --build-arg JL_VERSION_PATCH=$JL_VERSION_PATCH
         -t $image_name .`)
end

if length(ARGS) > 0 && ARGS[1] == "shell"
    run(`docker run --rm -it -v $(pwd()):/var/host $image_name bash`)
end

if length(ARGS) > 0 && ARGS[1] == "zip"
    rm(base_zip; force=true)
    cmd = `zip --symlinks -r -9 /var/host/$base_zip .`
    run(`docker run --rm -it -v $(pwd()):/var/host $image_name $cmd`)
end

if length(ARGS) > 0 && ARGS[1] == "deploy"
    AWSCore.Services.s3("PUT", "/$source_bucket/$base_zip",
                       headers=Dict("x-amz-acl" => "public-read"),
                       Body=read(base_zip))
    AWSLambda.deploy_jl_lambda_base(bucket = source_bucket, base_zip = base_zip)
end
