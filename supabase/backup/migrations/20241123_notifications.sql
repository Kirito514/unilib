-- Create notifications table
create table if not exists notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  message text not null,
  type text not null check (type in ('info', 'success', 'warning', 'achievement', 'reminder')),
  is_read boolean default false,
  link text,
  created_at timestamptz default now()
);

-- Enable RLS
alter table notifications enable row level security;

-- Create policies
create policy "Users can view their own notifications"
  on notifications for select
  using (auth.uid() = user_id);

create policy "Users can update their own notifications"
  on notifications for update
  using (auth.uid() = user_id);

create policy "Users can insert their own notifications"
  on notifications for insert
  with check (auth.uid() = user_id);

-- Create indexes
create index notifications_user_id_idx on notifications(user_id);
create index notifications_created_at_idx on notifications(created_at desc);
