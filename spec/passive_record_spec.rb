require 'spec_helper'

describe Model do
  describe "with a simple model including PR" do
    let!(:model) { SimpleModel.create(foo: value) }
    let(:value) { 'foo_value' }

    describe "#id" do
      it 'should be retrievable by id' do
        expect(SimpleModel.find_by(model.id)).to eq(model)
      end
    end

    context 'should be enumerable over models' do
      describe "#count" do
        it 'should indicate the size of the models list' do
          expect { SimpleModel.create }.to change { SimpleModel.count }.by(1)
        end
      end
    end

    context 'querying by attributes' do
      describe "#find_by" do
        it 'should be retrievable by query' do
          expect(SimpleModel.find_by(foo: 'foo_value')).to eq(model)
        end

        xit 'should support nested queries' do
          post = Post.create
          user = User.create
          
          comment = post.create_comment(user: user)
          #  ...  = user.create_comment post: post

          posts_with_comments_by_user = Post.find_by comments: { user: user }

          expect(posts_with_comments_by_user).to eq([comment])
        end
      end
    end
  end

  context 'hooks' do
    context 'after create hooks' do
      it 'should use a symbol to invoke a method' do
        expect(Child.create.name).to eq("Alice")
      end

      it 'should use a block' do
        expect(Dog.create.sound).to eq("bark")
      end

      it 'should use an inherited block' do
        expect(Parent.create.created_at).to be_a(Time)
      end
    end
  end

  context 'associations' do
    context 'one-to-one relationships' do
      let(:child) { Child.create }
      let(:another_child) { Child.create }

      it 'should create children' do
        expect { child.create_dog }.to change { Dog.count }.by(1)
        expect(child.dogs.first).to eq(Dog.last)
      end

      it 'should have inverse relationships' do
        dog = child.create_dog
        expect(dog.child).to eq(child)
        another_dog = another_child.create_dog
        expect(another_dog.child).to eq(another_child)
      end
    end

    context 'one-to-many relationships' do
      let(:parent) { Parent.create }

      it 'should create children' do
        expect { parent.create_child }.to change{ Child.count }.by(1)
        expect(parent.children).to all(be_a(Child))
      end

      it 'should create inverse relationships' do
        child = parent.create_child
        expect(child.parent).to eq(parent)

        another_child = parent.create_child
        expect(another_child.parent).to eq(parent)

        expect(child.id).not_to eq(another_child.id)
        expect(parent.children).to eq([child, another_child])
      end
    end

    context 'one-to-many through relationships' do
      let(:parent) { Parent.create }
      let(:child) { parent.create_child }
      subject(:dogs) { parent.dogs }

      it 'should collect children of children' do
        child.create_dog
        expect(dogs).to all(be_a(Dog))
        expect(dogs.first).to eq(child.dogs.first)
      end
    end

    context 'many-to-many' do
      let(:patient) { Patient.create }
      let(:doctor)  { Doctor.create }
      let!(:appointment) { Appointment.create(patient: patient, doctor: doctor) }

      it 'should manage many-to-many relations' do
        expect(appointment.doctor).to eq(doctor)
        expect(appointment.patient).to eq(patient)

        expect(patient.doctors).to eq([doctor])
        expect(doctor.patients).to eq([patient])
      end
    end

    context 'self-referential many-to-many' do
      let!(:user_a) { User.create }
      let!(:user_b) { User.create }

      it 'should permit relations' do
        expect(user_a.friends).to be_empty

        # need to create bidirectional friendship
        Friendship.create(user: user_a, friend: user_b)
        Friendship.create(user: user_b, friend: user_a)

        expect(user_a.friends).to eq([user_b])
        expect(user_b.friends).to eq([user_a])
      end
    end
  end
end
