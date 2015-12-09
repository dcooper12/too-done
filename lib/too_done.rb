require "too_done/version"
require "too_done/init_db"
require "too_done/user"
require "too_done/session"

require "too_done/to_do_list"
require "too_done/task"

require "thor"
require "pry"

module TooDone
  class App < Thor

    desc "add 'TASK'", "Add a TASK to a todo list."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list which the task will be filed under."
    option :date, :aliases => :d,
      :desc => "A Due Date in YYYY-MM-DD format."
    def add(task)
      list = ToDoList.find_or_create_by(name: options[:list] , user_id:  current_user.id)
      Task.create(name: task, list_id: list.id, due_date: options[:date])
    end

    desc "edit", "Edit a task from a todo list."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list whose tasks will be edited."
    def edit
      list = ToDoList.find_by(user_id: current_user.id, name: options[:list]) 
        if list == nil
          puts "No list"
          exit                                                                     
        end                         
      tasks = Task.where(list_id: list.id, completed: false)  
        tasks.each do |task| 
          puts "Incompleted task: #{task.name} | task-id: #{task.id}"
        end
        puts "Please choose task"
        task_id = STDIN.gets.chomp.to_i
        puts "Edit title"  
        new_title = STDIN.gets.chomp.to_s
        puts "Modify due date in the following format: YYYY-MM-DD."
        new_due_date = STDIN.gets.chomp

        edit_task = Task.find(task_id)
        edit_task.name = new_title unless new_title.empty?
        edit_task.new_due_date = new_due_date unless new_due_date.empty?
        edit_task.update
        puts "Update complete"
    end

    desc "done", "Mark a task as completed."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list whose tasks will be completed."
    def done
      list = ToDoList.find_by(user_id: current_user.id, name: options[:list])
      if list == nil 
        puts "No list found."                     
        exit
      end

      tasks = Task.where(completed: false, list_id: list.id)
        tasks.each do |task|
          puts "Task Name: #{task.name} | Task id: #{task.id} | Task Completed: #{task.completed}"
        end
      puts "Please choose a task" 
      done = STDIN.gets.chomp.to_i               
      tasks = Task.update(done, completed: true)
    end

    desc "show", "Show the tasks on a todo list in reverse order."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list whose tasks will be shown."
    option :completed, :aliases => :c, :default => false, :type => :boolean,
      :desc => "Whether or not to show already completed tasks."
    option :sort, :aliases => :s, :enum => ['history', 'overdue'],
      :desc => "Sorting by 'history' (chronological) or 'overdue'.
      \t\t\t\t\tLimits results to those with a due date."
    def show
      list = ToDoList.find_by(user_id: current_user.id, name: options[:list]) 
        if list == nil
          puts "No list found"
          exit
        end

      tasks = Task.where(completed: false, list_id: list.id)
      tasks = tasks.where(completed: false) unless options[:completed] 
        if tasks == nil
          puts "No tasks found."
          exit
        end
                                                      
      tasks = tasks.order(due_date: :desc) 
      tasks = tasks.order due_date: :asc if options[:sort] == 'history' 
      tasks.each do |task|
        puts "Task name: #{task.name} | Task id: #{task.id} | Completed: #{task.completed} | Due Date: #{task.due_date}"
      end
    end

    desc "delete [LIST OR USER]", "Delete a todo list or a user."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list which will be deleted (including items)."
    option :user, :aliases => :u,
      :desc => "The user which will be deleted (including lists and items)."
    def delete
      # BAIL if both list and user options are provided
      # BAIL if neither list or user option is provided
      # find the matching user or list
      # BAIL if the user or list couldn't be found
      # delete them (and any dependents)
    end

    desc "switch USER", "Switch session to manage USER's todo lists."
    def switch(username)
      user = User.find_or_create_by(name: username)
      user.sessions.create
    end

    private
    def current_user
      Session.last.user
    end
  end
end

# binding.pry
TooDone::App.start(ARGV)
