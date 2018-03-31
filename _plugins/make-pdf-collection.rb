Jekyll::Hooks.register :site, :post_read do |site|
  pdfs = []
  site.config['pdfdirs'].each do |pdfdir|
    Dir[pdfdir + '/*.pdf'].each do |pdf|
      file = {}
      stat = File::Stat.new(pdf)
      file['path'] = pdf
      file['size'] = stat.size
      file['ctime'] = stat.ctime
      file['mtime'] = stat.mtime
      pdfs << file
    end
  end
  site.data['pdfs'] = pdfs
end
