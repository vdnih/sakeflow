import Link from 'next/link';
import { Category } from '@/libs/microcms';
import styles from './index.module.css';

type Props = {
  category: Category;
  hasLink?: boolean;
};

export default function CategoryListItem({ category, hasLink = true }: Props) {
  if (hasLink) {
    return (
      <Link href={`/categories/${category.id}`} className={styles.tag}>
        #{category.name}
      </Link>
    );
  }
  return <span className={styles.tag}>#{category.name}</span>;
}
