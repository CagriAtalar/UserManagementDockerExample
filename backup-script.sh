#!/bin/bash

echo "🚀 Backup Manager başlatılıyor..."

# PostgreSQL bağlantı bilgileri
export PGPASSWORD=password

# Logs dizinini oluştur
mkdir -p /var/logs/archive

# Ana veri tabanından backup al
backup_database() {
    echo "📦 Veri tabanı backup'ı alınıyor: $(date)"
    
    # pg_dump ile tam backup
    pg_dump -h postgres-master -U postgres -d userdb > /var/logs/full_backup_$(date +%Y%m%d_%H%M%S).sql
    
    # Backup'ı backup PostgreSQL'e restore et
    pg_dump -h postgres-master -U postgres -d userdb | psql -h postgres-backup -U postgres -d userdb
    
    echo "✅ Backup tamamlandı: $(date)"
}

# İlk backup'ı al
echo "🔄 İlk backup alınıyor..."
backup_database

# Her 5 dakikada bir backup al
while true; do
    echo "⏰ 5 dakika bekleniyor..."
    sleep 300
    
    # Sadece değişen verileri backup al (incremental)
    echo "🔄 Incremental backup alınıyor..."
    
    # Son backup'tan sonraki değişiklikleri al
    pg_dump -h postgres-master -U postgres -d userdb --data-only --where="updated_at > (SELECT MAX(updated_at) FROM users)" > /var/logs/incremental_$(date +%Y%m%d_%H%M%S).sql
    
    # Backup'ı backup PostgreSQL'e uygula
    pg_dump -h postgres-master -U postgres -d userdb | psql -h postgres-backup -U postgres -d userdb
    
    echo "✅ Incremental backup tamamlandı: $(date)"
done
