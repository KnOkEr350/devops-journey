#!/bin/bash
# add-user.sh - простое добавление пользователя

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Запусти с sudo!"
  exit 1
fi

USERNAME=$1
GROUPS=$2

if [ -z "$USERNAME" ]; then
  echo "❌ Укажи имя пользователя!"
  echo "Пример: sudo ./add-user.sh alice www-data,sudo"
  exit 1
fi

echo "👤 Создаю пользователя: $USERNAME"

# Создать пользователя
useradd -m -s /bin/bash $USERNAME

if [ $? -ne 0 ]; then
  echo "❌ Ошибка создания пользователя!"
  exit 1
fi

# Сгенерировать пароль
PASSWORD=$(openssl rand -base64 8)
echo "$USERNAME:$PASSWORD" | chpasswd

echo "✅ Создан!"
echo "🔑 Временный пароль: $PASSWORD"

# Добавить в группы (если указаны)
if [ -n "$GROUPS" ]; then
  # Разделить группы по запятой
  IFS=',' read -ra GROUP_ARRAY <<< "$GROUPS"
  
  for group in "${GROUP_ARRAY[@]}"; do
    # Проверить что группа существует
    if ! getent group "$group" >/dev/null; then
      echo "⚠️  Группа $group не существует, создаю..."
      groupadd "$group"
    fi
    
    # Добавить в группу
    usermod -aG "$group" $USERNAME
    
    if [ $? -eq 0 ]; then
      echo "✅ Добавлен в группу: $group"
    else
      echo "❌ Ошибка добавления в группу: $group"
    fi
  done
fi

# Настроить SSH
echo "🔧 Настраиваю SSH..."

SSH_DIR="/home/$USERNAME/.ssh"

# Создать директорию
mkdir -p "$SSH_DIR"

if [ !  -d "$SSH_DIR" ]; then
  echo "❌ Не удалось создать $SSH_DIR"
  exit 1
fi

# Создать файл
touch "$SSH_DIR/authorized_keys"

# Установить права
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/authorized_keys"

# Сменить владельца
chown -R "$USERNAME:$USERNAME" "$SSH_DIR"

if [ $? -eq 0 ]; then
  echo "✅ SSH настроен"
else
  echo "❌ Ошибка настройки SSH"
fi

echo ""
echo "📝 Чтобы добавить SSH ключ:"
echo "   sudo nano $SSH_DIR/authorized_keys"
echo "   (вставь публичный ключ пользователя)"

