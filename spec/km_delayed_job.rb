require 'setup'
require 'delayed_job'
require 'benchmark'
Delayed::Worker.backend = :test

describe KM do
  context "using delayed_job for sending logs" do
    before do
      KM::reset
      now = Time.now
      Time.stub!(:now).and_return(now)
      FileUtils.rm_f KM::log_name(:error)
      FileUtils.rm_f KM::log_name(:query)
      Helper.clear
      Delayed::Job.delete_all
    end
    it "should create a delayed job" do
      KM::init 'KM_KEY', :log_dir => __('log'), :host => '127.0.0.1:9292', :use_delayed_job => true
      KM::identify 'bob'
      expect {
        KM::record 'Signup', 'age' => 26
      }.to change{Delayed::Job.count}.by(1)
    end
    context "when delayed jobs are run" do
      it "should send" do
        KM::init 'KM_KEY', :log_dir => __('log'), :host => '127.0.0.1:9292', :use_delayed_job => true
        KM::identify 'bob'
        KM::record 'Signup', 'age' => 26
        Delayed::Worker.new.work_off
        Delayed::Job.count.should == 0
        res = Helper.accept(:history).first.indifferent
        res[:path].should == '/e'
        res[:query]['_k'].first.should == 'KM_KEY'
        res[:query]['_p'].first.should == 'bob'
        res[:query]['_n'].first.should == 'Signup'
        res[:query]['_t'].first.should == Time.now.to_i.to_s
        res[:query]['age'].first.should == '26'
      end
    end
  end
end
