module WorkflowHelpers
  
  def nextid
    d = Nokogiri::XML(open("http://dor-dev.stanford.edu/fedora/management/getNextPID?xml=true&namespace=sdrtwo", {:http_basic_authentication=>["fedoraAdmin", "fedoraAdmin"]}))
    d.xpath("//pid").text
  end
  
end
World(WorkflowHelpers)