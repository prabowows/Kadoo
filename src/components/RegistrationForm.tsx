'use client';

import React, { useState } from 'react';
import { User, Phone, Mail, GraduationCap, Building2, MapPin, BookOpen, AlertCircle } from 'lucide-react';

interface RegistrationFormProps {
  onSubmit: (formData: {
    fullName: string;
    waNumber: string;
    waParentNumber: string;
    email: string;
    grade: string;
    schoolName: string;
    schoolCity: string;
    studyInterest: string;
  }) => void;
  isLoading?: boolean;
  errorMessage?: string | null;
}

const STUDY_PROGRAMS = [
  'Informatika / Ilmu Komputer',
  'Sistem Informasi',
  'Teknik Elektro / Robotika',
  'Desain Komunikasi Visual (DKV)',
  'Bisnis Digital / E-Commerce',
  'Manajemen & Kewirausahaan',
  'Akuntansi & Keuangan',
  'Ilmu Komunikasi / Broadcasting',
  'Hubungan Internasional',
  'Kedokteran / Farmasi',
  'Lainnya',
];

export default function RegistrationForm({
  onSubmit,
  isLoading = false,
  errorMessage = null,
}: RegistrationFormProps) {
  const [fullName, setFullName] = useState('');
  const [waNumber, setWaNumber] = useState('');
  const [waParentNumber, setWaParentNumber] = useState('');
  const [email, setEmail] = useState('');
  const [grade, setGrade] = useState('12');
  const [schoolName, setSchoolName] = useState('');
  const [schoolCity, setSchoolCity] = useState('');
  const [studyInterest, setStudyInterest] = useState('Informatika / Ilmu Komputer');
  const [customInterest, setCustomInterest] = useState('');
  const [formError, setFormError] = useState<string | null>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    // Validation
    if (!fullName.trim()) return setFormError('Nama lengkap wajib diisi');
    if (!waNumber.trim() || waNumber.trim().length < 9)
      return setFormError('Nomor WhatsApp aktif wajib diisi dengan benar');
    if (!waParentNumber.trim() || waParentNumber.trim().length < 9)
      return setFormError('Nomor WhatsApp orang tua wajib diisi');
    if (!email.trim() || !email.includes('@'))
      return setFormError('Email aktif wajib diisi dengan format valid');
    if (!schoolName.trim()) return setFormError('Asal sekolah wajib diisi');
    if (!schoolCity.trim()) return setFormError('Kota asal sekolah wajib diisi');

    const finalStudyInterest = studyInterest === 'Lainnya' && customInterest.trim() ? customInterest.trim() : studyInterest;

    onSubmit({
      fullName: fullName.trim(),
      waNumber: waNumber.trim(),
      waParentNumber: waParentNumber.trim(),
      email: email.trim(),
      grade,
      schoolName: schoolName.trim(),
      schoolCity: schoolCity.trim(),
      studyInterest: finalStudyInterest,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="w-full max-w-md mx-auto space-y-4">
      {(errorMessage || formError) && (
        <div className="p-3 rounded-xl bg-red-50 border border-red-200 text-red-700 text-xs flex items-start gap-2">
          <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
          <span>{formError || errorMessage}</span>
        </div>
      )}

      {/* Nama Lengkap */}
      <div>
        <label className="block text-xs font-bold text-gray-700 mb-1">
          Nama Lengkap <span className="text-red-500">*</span>
        </label>
        <div className="relative">
          <User className="w-4 h-4 text-gray-400 absolute left-3.5 top-3" />
          <input
            type="text"
            required
            placeholder="Contoh: Ahmad Fauzan"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            className="w-full pl-10 pr-3 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-amber-500 focus:bg-white text-gray-900"
          />
        </div>
      </div>

      {/* WhatsApp Siswa */}
      <div>
        <label className="block text-xs font-bold text-gray-700 mb-1">
          Nomor WhatsApp Aktif Siswa <span className="text-red-500">*</span>
        </label>
        <div className="relative">
          <Phone className="w-4 h-4 text-gray-400 absolute left-3.5 top-3" />
          <input
            type="tel"
            required
            placeholder="081234567890"
            value={waNumber}
            onChange={(e) => setWaNumber(e.target.value)}
            className="w-full pl-10 pr-3 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-amber-500 focus:bg-white text-gray-900"
          />
        </div>
        <p className="text-[11px] text-gray-400 mt-1">1 Nomor WA hanya berhak ikut 1x putaran</p>
      </div>

      {/* WhatsApp Ortu */}
      <div>
        <label className="block text-xs font-bold text-gray-700 mb-1">
          Nomor WhatsApp Orang Tua / Wali <span className="text-red-500">*</span>
        </label>
        <div className="relative">
          <Phone className="w-4 h-4 text-gray-400 absolute left-3.5 top-3" />
          <input
            type="tel"
            required
            placeholder="08xxxxxxxxxx"
            value={waParentNumber}
            onChange={(e) => setWaParentNumber(e.target.value)}
            className="w-full pl-10 pr-3 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-amber-500 focus:bg-white text-gray-900"
          />
        </div>
      </div>

      {/* Email */}
      <div>
        <label className="block text-xs font-bold text-gray-700 mb-1">
          Email Siswa <span className="text-red-500">*</span>
        </label>
        <div className="relative">
          <Mail className="w-4 h-4 text-gray-400 absolute left-3.5 top-3" />
          <input
            type="email"
            required
            placeholder="nama@gmail.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full pl-10 pr-3 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-amber-500 focus:bg-white text-gray-900"
          />
        </div>
      </div>

      {/* Kelas */}
      <div>
        <label className="block text-xs font-bold text-gray-700 mb-1">
          Kelas Saat Ini <span className="text-red-500">*</span>
        </label>
        <div className="relative">
          <GraduationCap className="w-4 h-4 text-gray-400 absolute left-3.5 top-3" />
          <select
            value={grade}
            onChange={(e) => setGrade(e.target.value)}
            className="w-full pl-10 pr-3 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-amber-500 focus:bg-white text-gray-900 appearance-none"
          >
            <option value="12">Kelas 12 SMA / SMK / MA</option>
            <option value="11">Kelas 11 SMA / SMK / MA</option>
            <option value="10">Kelas 10 SMA / SMK / MA</option>
            <option value="Alumni / Gap Year">Alumni / Gap Year</option>
          </select>
        </div>
      </div>

      {/* Asal Sekolah & Kota Sekolah (2 columns) */}
      <div className="grid grid-cols-2 gap-2.5">
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1">
            Asal Sekolah <span className="text-red-500">*</span>
          </label>
          <div className="relative">
            <Building2 className="w-4 h-4 text-gray-400 absolute left-3 top-3" />
            <input
              type="text"
              required
              placeholder="SMAN 1 Surabaya"
              value={schoolName}
              onChange={(e) => setSchoolName(e.target.value)}
              className="w-full pl-9 pr-2 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-xs sm:text-sm focus:outline-hidden focus:ring-2 focus:ring-amber-500 focus:bg-white text-gray-900"
            />
          </div>
        </div>
        <div>
          <label className="block text-xs font-bold text-gray-700 mb-1">
            Kota Sekolah <span className="text-red-500">*</span>
          </label>
          <div className="relative">
            <MapPin className="w-4 h-4 text-gray-400 absolute left-3 top-3" />
            <input
              type="text"
              required
              placeholder="Surabaya"
              value={schoolCity}
              onChange={(e) => setSchoolCity(e.target.value)}
              className="w-full pl-9 pr-2 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-xs sm:text-sm focus:outline-hidden focus:ring-2 focus:ring-amber-500 focus:bg-white text-gray-900"
            />
          </div>
        </div>
      </div>

      {/* Program Studi Diminati */}
      <div>
        <label className="block text-xs font-bold text-gray-700 mb-1">
          Program Studi yang Diminati <span className="text-red-500">*</span>
        </label>
        <div className="relative">
          <BookOpen className="w-4 h-4 text-gray-400 absolute left-3.5 top-3" />
          <select
            value={studyInterest}
            onChange={(e) => setStudyInterest(e.target.value)}
            className="w-full pl-10 pr-3 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-amber-500 focus:bg-white text-gray-900 appearance-none"
          >
            {STUDY_PROGRAMS.map((p) => (
              <option key={p} value={p}>
                {p}
              </option>
            ))}
          </select>
        </div>
        {studyInterest === 'Lainnya' && (
          <input
            type="text"
            required
            placeholder="Ketik prodi yang diminati..."
            value={customInterest}
            onChange={(e) => setCustomInterest(e.target.value)}
            className="mt-2 w-full px-3 py-2 bg-gray-50 border border-gray-300 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-amber-500 focus:bg-white text-gray-900"
          />
        )}
      </div>

      {/* Submit Button */}
      <div className="pt-2">
        <button
          type="submit"
          disabled={isLoading}
          className="w-full py-3.5 px-4 bg-gradient-to-r from-amber-500 via-orange-500 to-rose-500 text-white font-extrabold rounded-xl shadow-lg hover:brightness-110 active:scale-98 transition-all flex items-center justify-center gap-2 text-sm tracking-wide"
        >
          {isLoading ? (
            <span className="inline-block animate-spin mr-2">⏳</span>
          ) : (
            'LANJUT PILIH GAME DOORPRIZE ➔'
          )}
        </button>
      </div>
    </form>
  );
}
