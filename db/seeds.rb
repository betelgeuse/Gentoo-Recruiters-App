# This removes existing database entries
# but don't ask for confirmation - it's prohibited on Heroku
# In future (when we will have some important data)
# we should consider removing it (or at least disable it in production mode)
class SeedHelper
  attr_accessor :objects
  def initialize
    @objects = {}
  end

  # Read data from file
  # in each item replace values of fields given in replace_with_objects with objects
  # and create!
  def read_yaml(file, klass, replace_with_objects, &block)
    domain  = APP_CONFIG['seed']['users_domain']
    erb     = ERB.new(File.read(file)).result(binding)
    for item_array in  YAML::load(erb)
      name = item_array[0]
      hash = item_array[1]

      for field in replace_with_objects
        val = hash[field]
        if val.is_a?(Array)
          hash[field] = val.map { |n| @objects[n] }
        else
          hash[field] = @objects[val]
        end
      end

      if block.nil?
        @objects[name] = klass.create! hash
      else
        yield(name, hash, @objects, klass)
      end

    end
  end

  def answer_many(user, questions, answer_hash)
    for question in questions
      answer_hash[:question] = @objects[question]
      answer_hash[:owner] = @objects[user]
      Answer.create! answer_hash
    end
  end
end

# disable check of developer data (if mentor joined Gentoo long enough)
APP_CONFIG['developer_data']['check'] = false

# Remove existing database entries
User.destroy_all
Answer.destroy_all
Category.destroy_all
QuestionGroup.destroy_all
Question.destroy_all
UserCategory.destroy_all
UserQuestionGroup.destroy_all
User.destroy_all

seeder = SeedHelper.new

# Question categories
seeder.objects['ebuild']     = Category.create! :name => 'Ebuild quiz'
seeder.objects['mentoring']  = Category.create! :name => 'End of mentoring quiz'
seeder.objects['non_ebuild'] = Category.create! :name => 'Non-ebuild staff quiz'

# Question groups
seeder.objects['ebuild_group1'] = QuestionGroup.create! :name => 'ebuild_group1', :description => 'src_install implementations to comment on'

# Questions with text content - load from YAML file
seeder.read_yaml('db/fixtures/questions.yml', Question, ['categories', 'question_group']) do |name, hash, objects, klass|
  objects[name] = klass.create! (hash - {'content' => nil})
  objects["#{name}-content"] = QuestionContentText.create! :question => objects[name], :content => hash['content']
end

# Questions with multiple choice content - load from YAML file
seeder.read_yaml('db/fixtures/questions-multichoice.yml', Question, ['categories', 'question_group']) do |name, hash, objects, klass|
  objects[name] = klass.create!(hash - {'options' => nil, 'content' => nil})
  objects["#{name}-content"] = QuestionContentMultipleChoice.create! :question => objects[name], :content => hash['content']
  for opt in hash['options'].split(';')
    opt.strip!
    Option.create! :content => opt, :option_owner => objects["#{name}-content"]
  end
end

# Questions with email content - load from YAML file
seeder.read_yaml('db/fixtures/questions-email.yml', Question, ['categories', 'question_group']) do |name, hash, objects, klass|
  objects[name] = klass.create!(hash - {'content' => nil, 'req_text' => nil})
  objects["#{name}-content"] = QuestionContentEmail.create! :question => objects[name], :description=> hash['content'], :req_text => hash['req_text']
end
# Users - load from YAML file
seeder.read_yaml 'db/fixtures/users.yml', User, 'mentor'

# Categories for users
user_cats = [
  ['ebuild', 'mentor'],
  ['ebuild', 'recruit'],
  ['ebuild', 'middle'],
  ['ebuild', 'advanced'],
  ['mentoring', 'advanced'],
  ['mentoring', 'mentor']]

for uc in user_cats
  UserCategory.create! :category => seeder.objects[uc[0]], :user => seeder.objects[uc[1]]
end


ebuild_q  = ['ebuild_q1', 'ebuild_q2', 'ebuild_q3']
mentor_q  = ['mentor_q1', 'mentor_q2', 'mentor_q3']
non_q     = ['non_q1', 'non_q2']

# non-approved answers
ans_hash = {:content => 'Some answer'}
seeder.answer_many 'recruit',      ebuild_q, ans_hash
seeder.answer_many 'middle',  ebuild_q  - ['ebuild_q3'], ans_hash
seeder.answer_many 'advanced',     mentor_q, ans_hash

# approved answers
ans_hash[:approved] = true
seeder.answer_many 'mentor',       ebuild_q, ans_hash
seeder.answer_many 'advanced',     ebuild_q, ans_hash
seeder.answer_many 'mentor',       mentor_q, ans_hash

# reference answers for most questions
seeder.answer_many 'recruiter', mentor_q + ebuild_q + non_q - ['ebuild_q1', 'non_q1'],
  {:content => "Some reference answer", :reference => true}

advanced = seeder.objects['advanced']

for ans in advanced.answers
  Comment.create( :answer => ans, :owner => advanced.mentor, :content => "some comment")
end

for q in ebuild_q
  Comment.create( :answer => (seeder.objects[q].answer_of advanced), :owner => advanced.mentor,
    :content => "Some other comment")
end
