require_relative 'spec_helper'

describe "Archon record mappings" do

  def create_test_hash(fields, template = {})
    data = Hash[fields.map{ |field| [field, rand(36**4).to_s(36)] }]
    if data["URL"]
      data["URL"] = "http://example.com"
    end

    data.merge(template)
  end


  def transform(klass, data)
    results = []
    klass.transform(klass.new(data)){|obj| results << obj}
    results
  end


  def create_test_set(type, fields, template = {})
    data = create_test_hash(fields, template)
    pp data
    rec = Archon.record_type(type).new(data)
    results = transform(rec.class, data)

    return rec, results
  end


  def mapped?(rec_key, obj_key)
    @rec[rec_key].should_not be_nil
    @rec[rec_key].should eq(@obj.send(obj_key))
  end


  before(:all) do
    Thread.current[:archivesspace_client] = MockArchivesSpaceClient.new 
  end


  describe "Users" do
    before :all do

      @rec, results = create_test_set(
                                    :user, 
                                    %w(ID Login Email FirstName LastName DisplayName),
                                    {'IsAdminUser' => '1'}
                                    )
      @obj = results.shift
    end

    
    it "maps 'Login' to 'username'" do
      mapped?('Login', 'username')
    end


    it "maps 'Email' to 'email'" do
      mapped?('Email', 'email')
    end


    it "maps 'FirstName' to 'first_name'" do
      mapped?('FirstName', 'first_name')
    end


    it "maps 'LastName' to 'last_name'" do
      mapped?('LastName', 'last_name')
    end


    it "ignores archon users that aren't admins" do
      data = @rec.instance_variable_get(:@data).clone
      results = transform(Archon.record_type(:user), data)
      results.length.should eq(1)

      data['IsAdminUser'] = '0'
      results = transform(Archon.record_type(:user), data)
      results.length.should eq(0)
    end
  end


  describe "Repository" do
    before :all do
      @rec, results = create_test_set(:repository, %w(ID Name Code Address Address2 City State ZIPCode ZIPPlusFour Phone PhoneExtension Fax Email EmailSignature CountryID URL))
      @agent = results.shift
      @repo = results.shift
    end


    it "maps 'Name' to 'name'" do
      @repo['name'].should_not be_nil
      @repo['name'].should eq(@rec["Name"])
    end


    it "maps 'Code' to 'org_code'" do
      @repo['org_code'].should_not be_nil
      @repo['org_code'].should eq(@rec["Code"])
    end


    it "maps 'Address' to 'repository_with_agent.agent_representation.agent_contacts[0].address_1" do
      @agent['agent_contacts'][0]['address_1'].should eq(@rec["Address"])
    end


    it "maps 'Address2' to 'repository_with_agent.agent_representation.agent_contacts[0].address_2" do
      @agent['agent_contacts'][0]['address_2'].should eq(@rec["Address2"])
    end


    it "maps 'City' to 'repository_with_agent.agent_representation.agent_contacts[0].city" do
      @agent['agent_contacts'][0]['city'].should eq(@rec["City"])
    end


    it "maps 'State' to 'repository_with_agent.agent_representation.agent_contacts[0].region" do
      @agent['agent_contacts'][0]['region'].should eq(@rec["State"])
    end


    it "maps 'ZIPCode' and 'ZIPPlusFour' to 'repository_with_agent.agent_representation.agent_contacts[0].post_code" do
      @agent['agent_contacts'][0]['post_code'].should eq("#{@rec['ZIPCode']}-#{@rec['ZIPPlusFour']}")
    end


    it "maps 'Phone' and 'PhoneExtension' to 'repository_with_agent.agent_representation.agent_contacts[0].telephone" do
      @agent['agent_contacts'][0]['telephone'].should eq("#{@rec['Phone']} ext.#{@rec['PhoneExtension']}")
    end


    it "maps 'Fax' to 'repository_with_agent.agent_representation.agent_contacts[0].fax" do
      @agent['agent_contacts'][0]['fax'].should eq(@rec["Fax"])
    end


    it "maps 'Email' to 'repository_with_agent.agent_representation.agent_contacts[0].email" do
      @agent['agent_contacts'][0]['email'].should eq(@rec["Email"])
    end


    it "maps 'URL' to 'repository_with_agent.repository.url" do
      @repo['url'].should eq(@rec["URL"])
    end


    it "maps 'EmailSignature' to 'repository_with_agent.agent_representation.agent_contacts[0].email_signature" do
      @agent['agent_contacts'][0]['email_signature'].should eq(@rec["EmailSignature"])
    end


    it "maps 'CountryID' to 'repository_with_agent.agent_representation.agent_contacts[0].country" do
      @agent['agent_contacts'][0]['country'].should eq(@rec["CountryID"])
    end
  end
end
