require 'spec_helper'

describe EarnedBadgesController do

  context "as a professor" do
    before do
      @course = create(:course)
      @badge = create(:badge)
      @course.badges << @badge

      @student = create(:user)
      @student.courses << @course

      @team = create(:team, course: @course)
      @team.students << @student

      @earned_badge = create(:earned_badge, badge: @badge, student: @student)

      @professor = create(:user)
      @professor.courses << @course
      @membership = CourseMembership.where(user: @professor, course: @course).first.update(role: "professor")


      login_user(@professor)
      session[:course_id] = @course.id
      allow(Resque).to receive(:enqueue).and_return(true)
    end

    let(:valid_session) { { "current_course" => @course} }


    describe "GET index" do
      it "redirects to the badge for the earned badge" do
        get :index, :badge_id => @badge.id
        expect(response).to redirect_to(badge_path(@badge))
      end
    end

    describe "GET show" do
      it "returns the earned badge show page" do
        get :show, { :id => @earned_badge.id, :badge_id => @badge.id }
        expect(assigns(:title)).to eq("#{@student.name}'s #{@badge.name} badge")
        expect(assigns(:earned_badge)).to eq(@earned_badge)
        expect(response).to render_template(:show)
      end
    end

    describe "GET new" do
      it "display the create form" do
        get :new, :badge_id => @badge.id
        expect(assigns(:title)).to eq("Award #{@badge.name}")
        expect(assigns(:earned_badge)).to be_a_new(EarnedBadge)
        expect(response).to render_template(:new)
      end
    end

    describe "GET edit" do
      it "displays the edit form" do
        get :edit, {:id => @earned_badge.id, :badge_id => @badge.id}
        expect(assigns(:title)).to eq("Editing Awarded #{@badge.name}")
        expect(assigns(:earned_badge)).to eq(@earned_badge)
        expect(response).to render_template(:edit)
      end
    end

    describe "POST create" do
      it "creates the earned badge with valid attributes"  do
        skip "implement"
        params = attributes_for(:earned_badge)
        params[:student] = @student.id
        params[:badge_id] = @badge.id
        expect{ post :create, :badge_id => @badge.id, :earned_badge => params }.to change(EarnedBadge,:count).by(1)
      end

      it "doesn't create earned badges with invalid attributes" do
        expect{ post :create, :badge_id => @badge.id, earned_badge: attributes_for(:earned_badge, badge_id: @badge.id, student_id: nil) }.to_not change(EarnedBadge,:count)
      end
    end

    describe "POST mass_earn", working: true do
      subject { post :mass_earn, {id: @badge[:id], student_ids: @student_ids} }

      before do
        @course = create(:course)
        @badge = create(:badge, course_id: @course[:id])

        @professor = create(:user)
        @professor.courses << @course
        @membership = CourseMembership.where(user: @professor, course: @course).first.update(role: "professor")
        login_user(@professor)

        @students = create_list(:user, 2)
        @student_ids = @students.collect(&:id)
        allow(controller).to receive(:current_course) { @course }
      end

      context "earned badges are created" do
        before do
          @earned_badges = @students.collect do |student|
            create(:earned_badge, student_id: student[:id], badge: @badge)
          end
        end

        it "redirects to the badge page" do
          allow(controller).to receive(:parse_valid_earned_badges) { @earned_badges }
          expect(subject).to redirect_to(badge_path(@badge))
        end

        it "redirects back to the edit page" do
          allow(controller).to receive(:parse_valid_earned_badges) { [] }
          expect(subject).to redirect_to(mass_award_badge_url(id: @badge))
        end
      end
    end

    describe "send_earned_badge_notifications", working: true do
      before(:each) do
        @course = create(:course)
        @badge = create(:badge, course_id: @course[:id])
        @students = create_list(:user, 2)
        @student_ids = @students.collect(&:id)

        @professor = create(:user)
        @professor.courses << @course
        @membership = CourseMembership.where(user: @professor, course: @course).first.update(role: "professor")
        login_user(@professor)

        @earned_badges = @students.collect do |student|
          create(:earned_badge, student_id: student[:id], badge: @badge)
        end

        @controller = EarnedBadgesController.new
      end

      context "earned badges exist" do
        before(:each) do
          @controller.instance_variable_set(:@valid_earned_badges, @earned_badges)
        end

        it "should send a notification" do
          mail_responder = double("earned badge mail responder!!")
          allow(mail_responder).to receive(:deliver_now)
          allow(NotificationMailer).to receive(:earned_badge_awarded) { mail_responder }
          @earned_badges.each do |earned_badge|
            expect(NotificationMailer).to receive(:earned_badge_awarded).with(earned_badge[:id])
          end
          controller.instance_eval { send_earned_badge_notifications }
        end

        it "should record the notification in the environment log" do
          @earned_badges.each do |earned_badge|
            earned_badge_notification_message = "Sent an earned badge notification for EarnedBadge ##{earned_badge[:id]}"
            expect(controller.logger).to receive(:info).with(earned_badge_notification_message)
          end
          controller.instance_eval { send_earned_badge_notifications }
        end
      end

      context "no earned badges" do
        it "should not send any notifications" do
          @controller.instance_variable_set(:@valid_earned_badges, [])
          expect(NotificationMailer).not_to receive(:earned_badge_awarded)
        end
      end
    end

    describe "POST update" do
      it "updates the earned badge" do
        params = { feedback: "more feedback" }
        post :update, { id: @earned_badge.id, :badge_id => @badge.id, :earned_badge => params }
        @earned_badge.reload
        expect(@earned_badge.feedback).to eq("more feedback")
        expect(response).to redirect_to(badge_path(@badge))
      end
    end

    describe "PUT mass_update" do
      before(:each) do
      end
    end

    describe "GET mass_edit" do
      it "assigns params" do
        get :mass_edit, :id => @badge.id
        expect(assigns(:badge)).to eq(@badge)
        expect(assigns(:title)).to eq("Quick Award #{@badge.name}")
        expect(assigns(:students)).to eq([@student])
        expect(response).to render_template(:mass_edit)
      end

      describe "with teams" do
        it "assigns team and students for team" do
          # we verify only students on team assigned as @students
          other_student = create(:user)
          other_student.courses << @course

          team = create(:team, course: @course)
          team.students << @student

          get :mass_edit, {:id => @badge.id, :team_id => team.id}
          expect(assigns(:team)).to eq(team)
          expect(assigns(:students)).to eq([@student])
        end
      end

      describe "with no team id in params" do
        it "assigns all students if no team supplied" do
          # we verify non-team members also assigned as @students
          other_student = create(:user)
          other_student.courses << @course

          team = create(:team, course: @course)
          team.students << @student

          get :mass_edit, :id => @badge.id
          expect(assigns(:students)).to include(@student)
          expect(assigns(:students)).to include(other_student)
        end

      end

      describe "when badges can be earned multiple times" do
        it "assigns earned badges according to alphabetized students" do
          @student.update(last_name: "Zed")
          @student2 = create(:user, last_name: "Alpha")
          @student2.courses << @course
          get :mass_edit, :id => @badge.id
          expect(assigns(:earned_badges).count).to eq(2)
          expect(assigns(:earned_badges)[0].student_id).to eq(@student2.id)
          expect(assigns(:earned_badges)[1].student_id).to eq(@student.id)
        end
      end
    end


    describe "GET destroy" do
      it "destroys the earned badge" do
        expect{ get :destroy, { :id => @earned_badge, :badge_id => @badge.id } }.to change(EarnedBadge,:count).by(-1)
      end
    end
  end


  context "as student" do

    describe "protected routes" do
      [
        :index,
        :new,
        :create

      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route, {:badge_id => 1}).to redirect_to(:root)
          end
        end
    end


    describe "protected routes requiring id in params" do
      [
        :edit,
        :show,
        :update,
        :destroy
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, {:badge_id => 1, :id => "1"}).to redirect_to(:root)
        end
      end
    end

  end
end
