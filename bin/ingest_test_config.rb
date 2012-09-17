robots = []

Robot = Struct.new(:name, :queries, :files)
Query = Struct.new(:url, :code, :expectation)
DataFile = Struct.new(:path)

robots << robot = Robot.new("RegisterSdr", [], [])
robot.queries << Query.new(
    "{fedora}/objects/{druid}?format=xml", 200,
    "<objectProfile"
)
robot.queries << Query.new(
    "{fedora}/objects/{druid}/datastreams?format=xml", 200,
    "<objectDatastreams"
)
robot.queries << Query.new(
    "{fedora}/objects/{druid}/datastreams/workflows/content?format=xml", 200,
    "<workflows"
)

robots << robot = Robot.new("TransferObject", [], [])
robot.files << DataFile.new("{deposit}/{druid}")

robots << robot = Robot.new("ValidateBag", [], [])
robot.files << DataFile.new("{deposit}/{druid}/bag-info.txt")

robots << robot = Robot.new("PopulateMetadata", [], [])
robot.queries << Query.new(
    "{fedora}/objects/{druid}/datastreams?format=xml", 200,
    "relationshipMetadata|provenanceMetadata|identityMetadata"
)

robots << robot = Robot.new("VerifyAgreement", [], [])

robots << robot = Robot.new("CompleteDeposit", [], [])
robot.queries << Query.new(
    "{fedora}/objects/{druid}/datastreams/provenanceMetadata/content?format=xml", 200,
    '<agent name="SDR">'
)
robot.files << DataFile.new("{repository_path}")

