class AddImagifyTemplateKind < ActiveRecord::Migration
  def up
    TemplateKind.create(:name => 'imagify')
  end

  def down
    TemplateKind.find_by_name('imagify').destroy
  end
end
