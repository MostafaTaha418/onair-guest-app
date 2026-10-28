insert into public.platform_settings(key,value,domain,is_sensitive) values
 ('owner_response_hours','24','bookings',false),
 ('owner_response_reminder_minutes','[720,120]','bookings',false),
 ('quote_ttl_minutes','15','bookings',false),
 ('payment_pending_abandon_minutes','30','payments',false),
 ('auto_approve_conflict_refunds','true','refunds',true),
 ('remaining_payment_reminder_hours','[48,24]','payments',false),
 ('stay_reminder_hours','[24,2]','bookings',false),
 ('support_sla_hours','24','general',false),
 ('refund_sla_hours','72','refunds',true),
 ('default_settlement_schedule','"weekly"','settlements',true),
 ('otp_ttl_minutes','10','security',false),
 ('otp_max_attempts','5','security',false),
 ('otp_resend_seconds','60','security',false),
 ('review_comment_min_max','[10,1000]','general',false),
 ('upload_limits','{"image_mb":10,"pdf_mb":15}','general',false);
insert into public.property_types(key,label_ar,label_en,sort_order) values
 ('apartment','شقة','Apartment',1),('studio','استوديو','Studio',2),('duplex','دوبلكس','Duplex',3),
 ('chalet','شاليه','Chalet',4),('villa','فيلا','Villa',5),('room','غرفة','Room',6);
insert into public.workspaces(id,kind,display_name,verification_status)
values('00000000-0000-4000-8000-000000000001','platform','OnAir','approved');
insert into public.permissions(key,scope,label_ar) values
 ('workspace.manage','partner','إدارة الجهة'),('staff.manage','partner','إدارة الموظفين'),
 ('properties.view','partner','عرض العقارات'),('properties.manage','partner','إدارة العقارات'),
 ('calendar.manage','partner','إدارة التقويم'),('policies.manage','partner','إدارة السياسات'),
 ('bookings.view','partner','عرض الحجوزات'),('bookings.respond','partner','الرد على الحجوزات'),
 ('bookings.request_cancellation','partner','طلب إلغاء حجز'),('stays.handover','partner','تسليم الإقامة'),
 ('cash.collect','partner','تحصيل نقدي'),('damage.manage','partner','إدارة الأضرار'),
 ('finance.view','partner','عرض المالية'),
 ('platform.staff.manage','platform','إدارة موظفي المنصة'),('users.view','platform','عرض المستخدمين'),
 ('identity_documents.view','platform','عرض مستندات الهوية'),('partners.review','platform','مراجعة الشركاء'),
 ('properties.review','platform','مراجعة العقارات'),('properties.suspend','platform','إيقاف العقارات'),
 ('bookings.view_all','platform','عرض كل الحجوزات'),('bookings.monitor','platform','مراقبة الحجوزات'),
 ('bookings.record_phone_decision','platform','تسجيل القرار الهاتفي'),('bookings.manage','platform','إدارة الحجوزات'),
 ('support.handle','platform','معالجة الدعم'),('support.assign','platform','إسناد الدعم'),
 ('refunds.request','platform','طلب الاسترداد'),('refunds.approve','platform','اعتماد الاسترداد'),
 ('refunds.execute','platform','تنفيذ الاسترداد'),('refunds.verify','platform','التحقق من الاسترداد'),
 ('cash.receive_handover','platform','استلام العهدة'),
 ('settlements.prepare','platform','إعداد التسويات'),('settlements.approve','platform','اعتماد التسويات'),
 ('settlements.execute','platform','تنفيذ التسويات'),('settlements.verify','platform','التحقق من التسويات'),
 ('kashier.reconcile','platform','مطابقة كاشير'),('accounting.view','platform','عرض المحاسبة'),
 ('accounting.post_manual','platform','إنشاء قيد يدوي'),('accounting.approve','platform','اعتماد القيد'),
 ('reviews.moderate','platform','مراجعة التقييمات'),('tasks.assign','platform','إسناد المهام'),
 ('settings.manage','platform','إدارة الإعدادات'),('settings.manage_finance','platform','إدارة الإعدادات المالية'),
 ('audit.view','platform','عرض التدقيق');
insert into public.role_presets(key,scope,label_ar,permission_keys) values
 ('partner_owner','partner','مالك',array(select key from public.permissions where scope='partner')),
 ('partner_manager','partner','مدير',array(select key from public.permissions where scope='partner' and key not in ('workspace.manage','finance.view'))),
 ('partner_reception','partner','استقبال',array['properties.view','bookings.view','stays.handover','cash.collect']),
 ('partner_accountant','partner','محاسب',array['bookings.view','finance.view']),
 ('super_admin','platform','مدير المنصة',array(select key from public.permissions where scope='platform') || array['cash.collect']),
 ('admin','platform','مدير',array(select key from public.permissions where scope='platform' and key not in
   ('platform.staff.manage','settings.manage_finance','refunds.execute','refunds.verify','settlements.execute','settlements.verify'))),
 ('customer_support','platform','دعم العملاء',array['users.view','bookings.view_all','bookings.monitor','bookings.record_phone_decision','support.handle','refunds.request','reviews.moderate']),
 ('finance','platform','مالية',array['bookings.view_all','refunds.request','refunds.approve','refunds.execute','refunds.verify','cash.receive_handover','settlements.prepare','settlements.approve','settlements.execute','settlements.verify','kashier.reconcile','accounting.view','accounting.post_manual','accounting.approve']),
 ('field_staff','platform','موظف ميداني',array['cash.collect']);
insert into public.amenities(key,label_ar,label_en,icon,sort_order) values
 ('wifi','واي فاي','Wi-Fi','wifi',1),('air_conditioning','تكييف','Air conditioning','ac',2),
 ('kitchen','مطبخ','Kitchen','kitchen',3),('parking','موقف سيارات','Parking','parking',4),
 ('pool','حمام سباحة','Pool','pool',5),('washer','غسالة','Washer','washer',6);
