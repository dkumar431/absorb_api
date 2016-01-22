module AbsorbApi
  class CourseEnrollment < Base
    attr_reader :id, :course_id, :course_name, :course_version_id, :user_id, :full_name, :status, :progress, :score, :accepted_terms_and_conditions, :time_spent, :date_started, :date_completed, :enrollment_key_id, :certificate_id, :credits

    def initialize(attrs)
      attrs.each do |k,v|
        instance_variable_set("@#{k.underscore}", v) unless v.nil?
      end
    end


    def lessons
      api.get("users/#{self.user_id}/enrollments/#{self.course_id}/lessons", { "modifiedSince" => "2016-01-01"}).body.map! do |lesson_attrs|
        LessonEnrollment.new(lesson_attrs)
      end.reject { |lesson| AbsorbApi.configuration.ignored_lesson_types.include? lesson.type }
    end

    # gets all associated lessons given a collection of enrollments
    # all calls are called in parallel
    # enrollments are chunked in groups of 100 to keep typhoeus from getting bogged down
    # modifiedSince must be a DateTime object
    def self.lessons_from_collection(course_enrollments, modifiedSince)
      if modifiedSince.is_a? DateTime
        lessons = []
        course_enrollments.each_slice(100) do |enrollment_slice|
          api.in_parallel do
            enrollment_slice.each do |enrollment|
              lessons << api.get("users/#{enrollment.user_id}/enrollments/#{enrollment.course_id}/lessons", { "modifiedSince" => modifiedSince.to_s})
            end
          end
        end
        lessons.map { |response| response.body.map { |body| LessonEnrollment.new(body) } }.flatten.reject { |lesson| AbsorbApi.configuration.ignored_lesson_types.include? lesson.type }
      end
    end
  end
end
