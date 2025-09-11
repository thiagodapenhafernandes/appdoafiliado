class WebsiteClickImportService
  def initialize(user, file_path, file_name)
    @user = user
    @file_path = file_path
    @file_name = file_name
  end

  def import!
    import = WebsiteClickImport.create!(user: @user, file_name: @file_name, imported_at: Time.current)
    require 'csv'
    count = 0
    CSV.foreach(@file_path, headers: true, encoding: 'BOM|UTF-8') do |row|
      click_data = {
        click_id: row['ID dos Cliques'],
        click_time: DateTime.parse(row['Tempo dos Cliques']),
        region: row['Região dos Cliques'] || row['Região'] || 'Desconhecido',
        sub_id: row['Sub_id'].present? && row['Sub_id'] != '----' ? row['Sub_id'] : nil,
        referrer: row['Referenciador'] || row['Referrer'] || '',
        user: @user,
        website_click_import: import
      }
      next if click_data[:click_id].blank? || click_data[:click_time].blank?
      website_click = WebsiteClick.find_or_initialize_by(click_id: click_data[:click_id])
      website_click.assign_attributes(click_data)
      website_click.save!
      count += 1
    end
    count
  end
end
