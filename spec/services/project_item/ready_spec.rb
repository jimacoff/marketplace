# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::Ready do
  let(:project_item) { create(:project_item) }
  let(:issue) { double("Issue", id: 1) }
  let(:transition) { double("Transition") }

  context "(JIRA works without errors)" do
    before(:each) {
      wf_done_id = 6
      wf_in_progress_id = 7

      jira_client = double("Jira::Client",
                           jira_project_key: "MP",
                           jira_issue_type_id: 5,
                           wf_in_progress_id: wf_in_progress_id,
                           wf_done_id: wf_done_id)
      transition_start = double("Transition", id: "1", name: "____Start Progress____",
                                to: double(id: wf_in_progress_id.to_s))
      transition_done = double("Transition", id: "2", name: "____Done____",
                               to: double(id: wf_done_id.to_s))
      jira_class_stub = class_double(Jira::Client).
          as_stubbed_const(transfer_nested_constants: true)


      allow(jira_class_stub).to receive(:new).and_return(jira_client)
      allow(issue).to receive(:save).and_return(issue)
      allow(issue).to receive_message_chain(:transitions, :find) { issue }
      allow(jira_client).to receive(:create_service_issue).and_return(issue)
      allow(jira_client).to receive_message_chain(:Issue, :find) { issue }
      allow(jira_client).to receive_message_chain(:Issue, :build) { issue }
      allow(issue).to receive_message_chain(:transitions, :all) { [transition_start, transition_done] }
      allow(issue).to receive_message_chain(:transitions, :build) { transition }
      allow(transition). to receive(:save!).and_return(transition)
    }

    it "creates new project_item change" do
      described_class.new(project_item).call

      expect(project_item.project_item_changes.last).to be_ready
    end

    it "changes project_item status into ready on success" do
      described_class.new(project_item).call

      expect(project_item).to be_ready
    end

    it "uses activate message when project item status is changed to ready" do
      service = create(:open_access_service, activate_message: "Welcome!!!")
      offer = create(:offer, service: service)
      project_item = create(:project_item, offer: offer)

      described_class.new(project_item).call
      last_change = project_item.project_item_changes.last

      expect(last_change.message).to eq("Welcome!!!")
    end

    it "creates new JIRA issue and do the transition" do
      jira_client = Jira::Client.new

      expect(jira_client).to receive(:create_service_issue).with(project_item).and_return(issue)

      expect(transition).to receive(:save!).with("transition" => { "id" => "2" })

      described_class.new(project_item).call
      expect(project_item).to be_ready

    end

    context "Normal service project item" do
      it "sents ready and rate service emails to owner" do
        # project_item change email is sent only when there is more than 1 change
        project_item.new_change(status: :created, message: "ProjectItem is ready")

        expect { described_class.new(project_item).call }.
            to change { ActionMailer::Base.deliveries.count }.by(2)
        expect(ActionMailer::Base.deliveries[-2].subject).to start_with("Status of your")
        expect(ActionMailer::Base.deliveries.last.subject).to eq("EOSC Portal - Rate your service")
      end
    end

    context "Open access service project item" do
      let(:project_item) do
        create(:project_item,
               offer: create(:offer, service: create(:open_access_service)))
      end

      it "sends only rate service email to owner" do
        project_item.new_change(status: :ready, message: "ProjectItem is ready")

        expect { described_class.new(project_item).call }.
            to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(ActionMailer::Base.deliveries.last.subject).to eq("EOSC Portal - Rate your service")
        expect(ActionMailer::Base.deliveries.last.subject).to_not start_with("[ProjectItem #")
      end
    end
  end

  context "(JIRA raises Errors)" do
    let!(:jira_client) do
      client = double("Jira::Client", jira_project_key: "MP")
      jira_class_stub = class_double(Jira::Client).
          as_stubbed_const(transfer_nested_constants: true)
      allow(jira_class_stub).to receive(:new).and_return(client)
      client
    end

    it "sets jira error and raises exception on failed jira issue creation" do
      error = Jira::Client::JIRAIssueCreateError.new(project_item, "key" => "can not have value X")

      allow(jira_client).to receive(:create_service_issue).with(project_item).and_raise(error)

      expect { described_class.new(project_item).call }.to raise_error(error)
      expect(project_item.jira_errored?).to be_truthy
    end
  end
end
