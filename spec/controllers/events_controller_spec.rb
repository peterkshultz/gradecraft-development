require 'spec_helper'

describe EventsController do

  context "as a professor" do

    before do
      @course = create(:course)
      @professor = create(:user)
      @professor.courses << @course
      @membership = CourseMembership.where(user: @professor, course: @course).first.update(role: "professor")
      @event = create(:event)
      @course.events << @event
      login_user(@professor)

      session[:course_id] = @course.id
      allow(Resque).to receive(:enqueue).and_return(true)
    end

    describe "GET index" do
      it "assigns all events as @events" do
        allow(Resque).to receive(:enqueue).and_return(true)
        get :index
        expect(assigns(:events)).to eq([@event])
      end
    end

    describe "GET show" do
      it "assigns the requested event as @event" do
        get :show, {:id => @event.to_param}
        expect(assigns(:event)).to eq(@event)
      end
    end

    describe "GET new" do
      it "assigns a new event as @event" do
        get :new, {}
        expect(assigns(:event)).to be_a_new(Event)
      end
    end

    describe "GET edit" do
      it "assigns the requested event as @event" do
        get :edit, {:id => @event.to_param}
        expect(assigns(:event)).to eq(@event)
      end
    end

    describe "POST create" do
      describe "with valid params" do
        it "creates a new Event" do
          params = attributes_for(:event)
          expect{ post :create, :event => params }.to change(Event,:count).by(1)
        end

        it "assigns a newly created event as @event" do
          params = attributes_for(:event)
          post :create, :event => params
          expect(assigns(:event)).to be_a(Event)
          expect(assigns(:event)).to be_persisted
        end

        it "redirects to the created event" do
          params = attributes_for(:event)
          post :create, :event => params
          expect(response).to redirect_to(Event.last)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved event as @event" do
          allow_any_instance_of(Event).to receive(:save).and_return(false)
          post :create, {:event => { "name" => nil }}
          expect(assigns(:event)).to be_a_new(Event)
        end

        it "should not increase the Event count" do
          expect{ post :create, event: attributes_for(:event, name: nil) }.to_not change(Event,:count)
        end
      end
    end

    describe "PUT update" do
      describe "with valid params" do
        it "updates the requested event" do
          params = { name: "new name" }
          post :update, id: @event.id, :event => params
          @event.reload
          expect(response).to redirect_to(event_path(@event))
          expect(@event.name).to eq("new name")
        end
      end
    end

    describe "DELETE destroy" do

      it "destroys the requested event" do
        expect{ get :destroy, :id => @event }.to change(Event,:count).by(-1)
      end

      it "redirects to the events list" do
        expect{ get :destroy, :id => @event }.to change(Event,:count).by(-1)
        expect(response).to redirect_to(events_url)
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
            expect(get route).to redirect_to(:root)
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
          expect(get route, {:id => "1"}).to redirect_to(:root)
        end
      end
    end

  end

end
