# GradeEntryStudent represents a row (i.e. a student's grades for each question)
# in a grade entry form.
class GradeEntryStudent < ActiveRecord::Base
  belongs_to :user
  belongs_to :grade_entry_form

  has_many  :grades, :dependent => :destroy
  has_many  :grade_entry_items, :through => :grades

  has_and_belongs_to_many :tas

  validates_associated :user
  validates_associated :grade_entry_form

  validates_numericality_of :user_id, :only_integer => true, :greater_than => 0,
                            :message => I18n.t('invalid_id')
  validates_numericality_of :grade_entry_form_id, :only_integer => true, :greater_than => 0,
                            :message => I18n.t('invalid_id')

  # Given a row from a CSV file in the format
  # username,q1mark,q2mark,...,
  # create or update the GradeEntryStudent and Grade objects that
  # correspond to the student
  def self.create_or_update_from_csv_row(row, grade_entry_form)
    # Get the grade entry items for this grade entry form
    grade_entry_items = grade_entry_form.grade_entry_items

    working_row = row.clone
    user_name = working_row.shift

    # Attempt to find the student
    student = Student.find_by_user_name(user_name)
    if student.nil?
      raise I18n.t('grade_entry_forms.csv.invalid_user_name')
    end

    # Create the GradeEntryStudent if it doesn't already exist
    grade_entry_student = grade_entry_form.grade_entry_students.find_or_create_by_user_id(student.id)

    # Create or update the student's grade for each question
    grade_entry_items.each do |grade_entry_item|
      grade_for_grade_entry_item = working_row.shift
      grade = grade_entry_student.grades.find_or_create_by_grade_entry_item_id(grade_entry_item.id)
      grade.grade = grade_for_grade_entry_item
      if !grade.save
        raise RuntimeError.new(grade.errors)
      end
    end
  end


  def add_tas(tas)
    return unless self.valid?
    grade_entry_student_tas = self.tas
    tas = Array(tas)
    tas.each do |ta|
      if !grade_entry_student_tas.include? ta
        self.tas << ta
        grade_entry_student_tas += [ta]
      end
    end
    self.save
  end

  def remove_tas(ta_id_array)
    #if no tas to remove, return.
    return if ta_id_array == []
    grade_entry_student_tas = self.tas

    tas_to_remove = grade_entry_student_tas.find_all_by_id(ta_id_array)
    tas_to_remove.each do |ta_to_remove|
      self.tas.delete(ta_to_remove)
    end
    self.save
  end

end
